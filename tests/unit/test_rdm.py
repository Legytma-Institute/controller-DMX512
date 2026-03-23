import pytest

from controller_dmx512.core.rdm import (
    DiscoveryResult,
    RDMCommandClass,
    RDMUID,
    build_rdm_request,
    decode_discovery_response,
    parse_rdm_message,
    rdm_verify_checksum,
)


def _encode_discovery_response(uid: RDMUID) -> bytes:
    uid_bytes = uid.to_bytes()
    checksum = sum(uid_bytes) & 0xFFFF
    payload = uid_bytes + bytes([(checksum >> 8) & 0xFF, checksum & 0xFF])

    encoded = bytearray([0xFE] * 7)
    encoded.append(0xAA)
    for b in payload:
        encoded.append(b | 0xAA)
        encoded.append(b | 0x55)
    return bytes(encoded)


def test_build_and_parse_rdm_request_roundtrip():
    dest = RDMUID.from_str("1234:89abcdef")
    src = RDMUID.from_str("7fff:00000001")
    pkt = build_rdm_request(
        dest_uid=dest,
        src_uid=src,
        transaction_number=1,
        port_id=1,
        message_count=0,
        sub_device=0,
        command_class=RDMCommandClass.GET_COMMAND,
        parameter_id=0x0060,
        parameter_data=b"",
    )

    assert rdm_verify_checksum(pkt)
    msg = parse_rdm_message(pkt)

    assert msg.dest_uid == dest
    assert msg.src_uid == src
    assert msg.transaction_number == 1
    assert msg.command_class == RDMCommandClass.GET_COMMAND
    assert msg.parameter_id == 0x0060
    assert msg.parameter_data == b""


def test_decode_discovery_response_valid_uid():
    uid = RDMUID.from_str("0102:03040506")
    raw = _encode_discovery_response(uid)

    result, decoded = decode_discovery_response(raw)
    assert result == DiscoveryResult.VALID
    assert decoded == uid


def test_decode_discovery_response_collision_when_missing_aa():
    raw = bytes([0xFE] * 10)
    result, decoded = decode_discovery_response(raw)
    assert result == DiscoveryResult.COLLISION
    assert decoded is None


def test_decode_discovery_response_no_response_when_empty():
    result, decoded = decode_discovery_response(b"")
    assert result == DiscoveryResult.NO_RESPONSE
    assert decoded is None
