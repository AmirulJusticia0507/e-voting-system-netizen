"""Kriptografi untuk integritas suara (anti-tamper).

- `encrypt`/`decrypt` : enkripsi AMS-256-GCM dari pilihan suara (``candidate_id``).
- `compute_vote_hash`: HMAC-SHA256 chain hash (``prev_hash | candidate | nonce``)
  sehingga mengubahan satu data langsung merusak rantai dan mudah terdeteksi.

Kunci berasal dari ``settings.VOTE_ENCRYPTION_KEY`` (via ``.env``).
Key dev disediakan hanya untuk development; WAJIB diganti di produksi.
"""
import base64
import hashlib
import hmac
import secrets

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ALGO = "AES-256-GCM"
HASH_ALGO = "sha256"


def _derive_key(secret: str) -> bytes:
    # Pastikan 32 byte untuk AES-256
    return hashlib.sha256(secret.encode()).digest()


def encrypt(plaintext: str, secret: str) -> str:
    """Enkripsi string, kembalikan base64(iv + tag + ciphertext)."""
    key = _derive_key(secret)
    iv = secrets.token_bytes(12)
    aes = AESGCM(key)
    ct = aes.encrypt(iv, plaintext.encode(), None)
    return base64.b64encode(iv + ct).decode()


def decrypt(token: str, secret: str) -> str:
    """Dekripsi balikan dari ``encrypt`` dalam bentuk string plaintext."""
    key = _derive_key(secret)
    raw = base64.b64decode(token)
    iv, ct = raw[:12], raw[12:]
    aes = AESGCM(key)
    return aes.decrypt(iv, ct, None).decode()


def token_hex(nbytes: int = 16) -> str:
    """Random hex string (untuk nonce vote)."""
    return secrets.token_hex(nbytes)


def compute_vote_hash(previous_hash: str, candidate_id: int, nonce: str, secret: str) -> str:
    """HMAC-SHA256 dari ``prev_hash|candidate_id|nonce``."""
    key = _derive_key(secret)
    message = f"{previous_hash}|{candidate_id}|{nonce}"
    return hmac.new(key, message.encode(), hashlib.sha256).hexdigest()