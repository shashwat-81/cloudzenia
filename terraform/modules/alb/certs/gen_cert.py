"""Generate self-signed PEM for ALB/ACM import (UTC notBefore = now)."""
from datetime import datetime, timedelta, timezone
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
import ipaddress
import os
import sys

DNS_NAMES = [
    "wordpress-clodzenia.duckdns.org",
    "microservice-clodzenia.duckdns.org",
]
DIR = os.path.dirname(os.path.abspath(__file__))
KEY_PATH = os.path.join(DIR, "selfsigned.key")
CRT_PATH = os.path.join(DIR, "selfsigned.crt")

def main():
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    now = datetime.now(timezone.utc)
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "cloudzenia"),
        x509.NameAttribute(NameOID.COMMON_NAME, DNS_NAMES[0]),
    ])
    san = x509.SubjectAlternativeName([x509.DNSName(n) for n in DNS_NAMES])
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(hours=1))
        .not_valid_after(now + timedelta(days=825))
        .add_extension(san, critical=False)
        .sign(key, hashes.SHA256())
    )
    with open(KEY_PATH, "wb") as f:
        f.write(
            key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.TraditionalOpenSSL,
                serialization.NoEncryption(),
            )
        )
    with open(CRT_PATH, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    print("Wrote", KEY_PATH, CRT_PATH)

if __name__ == "__main__":
    main()
