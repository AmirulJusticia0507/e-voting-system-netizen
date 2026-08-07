"""Tanda tangan digital (Ed25519) untuk rekap hasil resmi (gaya Ci.Cii).

Kunci pemakaian: ``settings.RESULT_SIGNING_KEY`` (hex, opsional). Bila kosong,
fallback pakai ``SECRET_KEY`` — cocok untuk development, WAJIB kunci terpisah di produksi.

Skema: manifest (rekap) dibuat deterministik (JSON terurut), di-hash SHA-256, lalu
``signature = Ed25519Sign(private_key, manifest_bytes)``. Siapa pun yang punya
``public_key`` bisa memverifikasi keasliannya.
"""
import hashlib
import json

from django.conf import settings
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)
from cryptography.hazmat.primitives.serialization import PublicFormat, Encoding


def _seed() -> bytes:
    seed = getattr(settings, "RESULT_SIGNING_KEY", "") or getattr(settings, "SECRET_KEY", "dev-sign")
    return hashlib.sha256(str(seed).encode()).digest()


def _private() -> Ed25519PrivateKey:
    return Ed25519PrivateKey.from_private_bytes(_seed())


def public_key_hex() -> str:
    pub = _private().public_key()
    return pub.public_bytes(Encoding.Raw, PublicFormat.Raw).hex()


def canonical_manifest(obj) -> bytes:
    """Deterministic JSON (sort_keys) sebagai bahan hash & tanda tangan."""
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()


def manifest_hash(obj) -> str:
    return hashlib.sha256(canonical_manifest(obj)).hexdigest()


def sign(obj) -> str:
    return _private().sign(canonical_manifest(obj)).hex()


def verify(obj, signature_hex: str, public_key_hex: str) -> bool:
    """Verifikasi tanda tangan terhadap objek manifest."""
    try:
        pub = Ed25519PublicKey.from_public_bytes(bytes.fromhex(public_key_hex))
        pub.verify(bytes.fromhex(signature_hex), canonical_manifest(obj))
        return True
    except Exception:
        return False