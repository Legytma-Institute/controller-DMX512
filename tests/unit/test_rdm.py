import pytest

from controller_dmx512.core.rdm import (
    DiscoveryResult,
    PID_DEVICE_INFO,
    PID_DMX_START_ADDRESS,
    PID_IDENTIFY_DEVICE,
    PID_SUPPORTED_PARAMETERS,
    RDMCommandClass,
    RDMDeviceInfo,
    RDMNackReason,
    RDMPersonality,
    RDMResponseType,
    RDMUID,
    build_rdm_request,
    decode_discovery_response,
    parse_device_info_response,
    parse_rdm_message,
    parse_supported_parameters_response,
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


# --- RDMUID tests ---


def test_rdmuid_from_int_and_back():
    uid = RDMUID.from_int(0x123456789ABC)
    assert uid.manufacturer_id == 0x1234
    assert uid.device_id == 0x56789ABC
    assert uid.to_int() == 0x123456789ABC


def test_rdmuid_from_str_and_back():
    uid = RDMUID.from_str("abcd:12345678")
    assert uid.manufacturer_id == 0xABCD
    assert uid.device_id == 0x12345678
    assert str(uid) == "abcd:12345678"


def test_rdmuid_to_bytes_length():
    uid = RDMUID(0x0001, 0x00000002)
    b = uid.to_bytes()
    assert len(b) == 6
    assert b == bytes([0x00, 0x01, 0x00, 0x00, 0x00, 0x02])


def test_rdmuid_all_devices():
    uid = RDMUID.all_devices()
    assert uid.manufacturer_id == 0xFFFF
    assert uid.device_id == 0xFFFFFFFF


def test_rdmuid_invalid_manufacturer():
    with pytest.raises(ValueError):
        RDMUID(0x10000, 0)


def test_rdmuid_invalid_device():
    with pytest.raises(ValueError):
        RDMUID(0, 0x100000000)


# --- SET command roundtrip ---


def test_build_and_parse_set_command_roundtrip():
    dest = RDMUID.from_str("0001:00000010")
    src = RDMUID.from_str("7fff:00000001")
    pkt = build_rdm_request(
        dest_uid=dest,
        src_uid=src,
        transaction_number=5,
        port_id=1,
        message_count=0,
        sub_device=0,
        command_class=RDMCommandClass.SET_COMMAND,
        parameter_id=PID_DMX_START_ADDRESS,
        parameter_data=bytes([0x00, 0x0A]),
    )
    assert rdm_verify_checksum(pkt)
    msg = parse_rdm_message(pkt)
    assert msg.command_class == RDMCommandClass.SET_COMMAND
    assert msg.parameter_id == PID_DMX_START_ADDRESS
    assert msg.parameter_data == bytes([0x00, 0x0A])


# --- parse_device_info_response ---


def test_parse_device_info_response_basic():
    uid = RDMUID(0x0001, 0x00000001)
    data = bytearray(19)
    data[0] = 0x01  # protocol version high
    data[1] = 0x00  # protocol version low
    data[2] = 0x00  # model id high
    data[3] = 0x42  # model id low
    data[4] = 0x01  # product category high
    data[5] = 0x01  # product category low
    data[6:10] = (0x00010002).to_bytes(4, "big")  # software version
    data[10] = 0x00  # footprint high
    data[11] = 0x06  # footprint low = 6 channels
    data[12] = 0x01  # current personality
    data[13] = 0x03  # personality count
    data[14] = 0x00  # dmx start high
    data[15] = 0x01  # dmx start low
    data[16] = 0x00  # sub device count high
    data[17] = 0x00  # sub device count low
    data[18] = 0x02  # sensor count

    info = parse_device_info_response(uid, bytes(data))
    assert info.uid == uid
    assert info.rdm_protocol_version == 0x0100
    assert info.device_model_id == 0x0042
    assert info.dmx_footprint == 6
    assert info.current_personality == 1
    assert info.personality_count == 3
    assert info.dmx_start_address == 1
    assert info.sensor_count == 2


def test_parse_device_info_response_too_short():
    uid = RDMUID(0x0001, 0x00000001)
    with pytest.raises(ValueError):
        parse_device_info_response(uid, b"\x00" * 10)


# --- parse_supported_parameters_response ---


def test_parse_supported_parameters_response():
    data = bytes([0x00, 0x60, 0x00, 0xF0, 0x10, 0x00])
    pids = parse_supported_parameters_response(data)
    assert pids == [PID_DEVICE_INFO, PID_DMX_START_ADDRESS, PID_IDENTIFY_DEVICE]


def test_parse_supported_parameters_response_empty():
    pids = parse_supported_parameters_response(b"")
    assert pids == []


# --- RDMDeviceInfo defaults ---


def test_rdm_device_info_defaults():
    uid = RDMUID(0x0001, 0x00000001)
    info = RDMDeviceInfo(uid=uid)
    assert info.manufacturer_label == ""
    assert info.device_label == ""
    assert info.supported_parameters == []
    assert info.personalities == {}
    assert info.identifying is False


# --- RDMNackReason ---


def test_nack_reason_values():
    assert RDMNackReason.UNKNOWN_PID == 0x0000
    assert RDMNackReason.DATA_OUT_OF_RANGE == 0x0006


# --- RDMPersonality ---


def test_rdm_personality():
    p = RDMPersonality(index=1, dmx_footprint=6, description="6ch mode")
    assert p.index == 1
    assert p.dmx_footprint == 6
    assert p.description == "6ch mode"
