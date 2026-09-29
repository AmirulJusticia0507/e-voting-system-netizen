"""Run Django's development server together with a Cloudflare quick tunnel."""

import os
import re
import shutil
import subprocess
import sys
import threading
import time

from django.conf import settings
from django.core.management import CommandError
from django.core.management.commands.runserver import Command as DjangoRunServerCommand

URL_RE = re.compile(r"https://[a-z0-9-]+\.trycloudflare\.com")
BINARY_CANDIDATES = (
    r"C:\Program Files (x86)\cloudflared\cloudflared.exe",
    r"C:\Program Files\cloudflared\cloudflared.exe",
)


def find_cloudflared(explicit=None):
    if explicit:
        return explicit if os.path.exists(explicit) else shutil.which(explicit)
    return shutil.which("cloudflared") or next(
        (path for path in BINARY_CANDIDATES if os.path.exists(path)), None
    )


def origin_url(addrport):
    """Convert Django's addrport argument into a locally reachable URL."""
    if addrport.isdigit():
        host, port = "127.0.0.1", addrport
    elif addrport.startswith("["):
        host, _, port = addrport.partition("]:")
        host = host[1:]
    else:
        host, _, port = addrport.partition(":")
    if host in {"0.0.0.0", "::", ""}:
        host = "127.0.0.1"
    return f"http://{host}:{port or '8000'}"


def start_tunnel(binary, origin, timeout=45):
    process = subprocess.Popen(
        [binary, "tunnel", "--url", origin],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
    )
    found = threading.Event()
    urls = []

    def relay_output():
        for line in process.stdout:
            line = line.rstrip()
            match = URL_RE.search(line)
            if match:
                urls.append(match.group(0))
                found.set()
            elif "ERR" in line or "failed" in line.lower():
                print(f"  [cloudflared] {line}", file=sys.stderr, flush=True)

    threading.Thread(target=relay_output, daemon=True).start()

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if found.wait(timeout=0.5):
            return process, urls[0]
        if process.poll() is not None:
            raise CommandError(
                "cloudflared berhenti sebelum memberi URL. "
                "Jalankan dengan --no-tunnel untuk menonaktifkan tunnel."
            )
    process.kill()
    raise CommandError(f"cloudflared tidak memberi URL dalam {timeout} detik.")


class Command(DjangoRunServerCommand):
    help = "Jalankan development server dan Cloudflare quick tunnel sekaligus."

    def add_arguments(self, parser):
        super().add_arguments(parser)
        parser.add_argument(
            "--no-tunnel",
            action="store_true",
            help="Jalankan development server tanpa Cloudflare tunnel.",
        )
        parser.add_argument(
            "--tunnel-bin",
            metavar="PATH",
            help="Lokasi cloudflared; dideteksi otomatis bila tidak diisi.",
        )

    def handle(self, *args, **options):
        tunnel = None
        if not options["no_tunnel"]:
            binary = find_cloudflared(options["tunnel_bin"])
            if binary is None:
                raise CommandError(
                    "cloudflared tidak ditemukan. Install cloudflared, gunakan "
                    "--tunnel-bin PATH, atau jalankan dengan --no-tunnel."
                )

            tunnel, public_url = start_tunnel(binary, origin_url(options["addrport"]))
            os.environ["PUBLIC_BASE_URL"] = public_url
            settings.PUBLIC_BASE_URL = public_url
            self.stdout.write(self.style.SUCCESS(f"Tunnel publik : {public_url}"))
            self.stdout.write("Tekan CTRL+C untuk menghentikan server dan tunnel.")

        try:
            super().handle(*args, **options)
        finally:
            if tunnel is not None and tunnel.poll() is None:
                tunnel.terminate()
                try:
                    tunnel.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    tunnel.kill()
                    tunnel.wait(timeout=10)
                self.stdout.write("Tunnel dihentikan.")
