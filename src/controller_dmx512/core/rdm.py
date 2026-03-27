from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple

RDM_START_CODE = 0xCC
RDM_SUB_START_CODE = 0x01

ALL_DEVICES_UID_INT = (0xFFFF << 32) | 0xFFFFFFFF


def rdm_checksum(data: bytes) -> int:
    return sum(data) & 0xFFFF


def rdm_append_checksum(packet_wo_checksum: bytes) -> bytes:
    csum = rdm_checksum(packet_wo_checksum)
    return packet_wo_checksum + bytes([(csum >> 8) & 0xFF, csum & 0xFF])


def rdm_verify_checksum(packet: bytes) -> bool:
    if len(packet) < 3:
        return False
    expected = rdm_checksum(packet[:-2])
    actual = (packet[-2] << 8) | packet[-1]
    return expected == actual


@dataclass(frozen=True, slots=True)
class RDMUID:
    manufacturer_id: int
    device_id: int

    def __post_init__(self) -> None:
        if not (0 <= self.manufacturer_id <= 0xFFFF):
            raise ValueError("manufacturer_id out of range")
        if not (0 <= self.device_id <= 0xFFFFFFFF):
            raise ValueError("device_id out of range")

    @staticmethod
    def from_int(uid_int: int) -> "RDMUID":
        if not (0 <= uid_int <= 0xFFFFFFFFFFFF):
            raise ValueError("uid_int out of range")
        return RDMUID((uid_int >> 32) & 0xFFFF, uid_int & 0xFFFFFFFF)

    @staticmethod
    def from_str(uid: str) -> "RDMUID":
        parts = uid.strip().lower().split(":")
        if len(parts) != 2:
            raise ValueError("invalid uid format")
        return RDMUID(int(parts[0], 16), int(parts[1], 16))

    def to_int(self) -> int:
        return ((self.manufacturer_id & 0xFFFF) << 32) | (self.device_id & 0xFFFFFFFF)

    def to_bytes(self) -> bytes:
        return bytes(
            [
                (self.manufacturer_id >> 8) & 0xFF,
                self.manufacturer_id & 0xFF,
                (self.device_id >> 24) & 0xFF,
                (self.device_id >> 16) & 0xFF,
                (self.device_id >> 8) & 0xFF,
                self.device_id & 0xFF,
            ]
        )

    @staticmethod
    def all_devices() -> "RDMUID":
        return RDMUID(0xFFFF, 0xFFFFFFFF)

    def __str__(self) -> str:
        return f"{self.manufacturer_id:04x}:{self.device_id:08x}"


class RDMCommandClass(int, Enum):
    DISCOVERY_COMMAND = 0x10
    DISCOVERY_COMMAND_RESPONSE = 0x11
    GET_COMMAND = 0x20
    GET_COMMAND_RESPONSE = 0x21
    SET_COMMAND = 0x30
    SET_COMMAND_RESPONSE = 0x31


class RDMResponseType(int, Enum):
    ACK = 0x00
    ACK_TIMER = 0x01
    NACK_REASON = 0x02
    ACK_OVERFLOW = 0x03


class DiscoveryResult(Enum):
    NO_RESPONSE = "no_response"
    VALID = "valid"
    COLLISION = "collision"


# --- Discovery PIDs ---
PID_DISC_UNIQUE_BRANCH = 0x0001
PID_DISC_MUTE = 0x0002
PID_DISC_UN_MUTE = 0x0003

# --- Required PIDs (ANSI E1.20 §10) ---
PID_SUPPORTED_PARAMETERS = 0x0050
PID_DEVICE_INFO = 0x0060
PID_DEVICE_MODEL_DESCRIPTION = 0x0080
PID_MANUFACTURER_LABEL = 0x0081
PID_DEVICE_LABEL = 0x0082
PID_SOFTWARE_VERSION_LABEL = 0x00C0
PID_DMX_PERSONALITY = 0x00E0
PID_DMX_PERSONALITY_DESCRIPTION = 0x00E1
PID_DMX_START_ADDRESS = 0x00F0
PID_SENSOR_DEFINITION = 0x0200
PID_SENSOR_VALUE = 0x0201
PID_IDENTIFY_DEVICE = 0x1000


class RDMNackReason(int, Enum):
    UNKNOWN_PID = 0x0000
    FORMAT_ERROR = 0x0001
    HARDWARE_FAULT = 0x0002
    PROXY_REJECT = 0x0003
    WRITE_PROTECT = 0x0004
    UNSUPPORTED_COMMAND_CLASS = 0x0005
    DATA_OUT_OF_RANGE = 0x0006
    BUFFER_FULL = 0x0007
    PACKET_SIZE_UNSUPPORTED = 0x0008
    SUB_DEVICE_OUT_OF_RANGE = 0x0009
    PROXY_BUFFER_FULL = 0x000A


@dataclass(frozen=True, slots=True)
class RDMMessage:
    raw: bytes
    dest_uid: RDMUID
    src_uid: RDMUID
    transaction_number: int
    command_class: int
    parameter_id: int
    parameter_data: bytes
    port_id_or_response_type: int
    message_count: int
    sub_device: int


def build_rdm_request(
    *,
    dest_uid: RDMUID,
    src_uid: RDMUID,
    transaction_number: int,
    port_id: int,
    message_count: int,
    sub_device: int,
    command_class: int,
    parameter_id: int,
    parameter_data: bytes = b"",
) -> bytes:
    if not (0 <= transaction_number <= 0xFF):
        raise ValueError("transaction_number out of range")
    if not (0 <= port_id <= 0xFF):
        raise ValueError("port_id out of range")
    if not (0 <= message_count <= 0xFF):
        raise ValueError("message_count out of range")
    if not (0 <= sub_device <= 0xFFFF):
        raise ValueError("sub_device out of range")
    if not (0 <= parameter_id <= 0xFFFF):
        raise ValueError("parameter_id out of range")
    if len(parameter_data) > 0xFF:
        raise ValueError("parameter_data too long")

    header = bytearray()
    header.append(RDM_START_CODE)
    header.append(RDM_SUB_START_CODE)
    header.append(0)
    header += dest_uid.to_bytes()
    header += src_uid.to_bytes()
    header.append(transaction_number & 0xFF)
    header.append(port_id & 0xFF)
    header.append(message_count & 0xFF)
    header += bytes([(sub_device >> 8) & 0xFF, sub_device & 0xFF])
    header.append(command_class & 0xFF)
    header += bytes([(parameter_id >> 8) & 0xFF, parameter_id & 0xFF])
    header.append(len(parameter_data) & 0xFF)
    header += parameter_data

    message_length = len(header) + 2
    header[2] = message_length & 0xFF

    return rdm_append_checksum(bytes(header))


def parse_rdm_message(packet: bytes) -> RDMMessage:
    if len(packet) < 26:
        raise ValueError("packet too short")
    if packet[0] != RDM_START_CODE or packet[1] != RDM_SUB_START_CODE:
        raise ValueError("invalid start code")
    msg_len = packet[2]
    if msg_len != len(packet):
        raise ValueError("message length mismatch")
    if not rdm_verify_checksum(packet):
        raise ValueError("checksum mismatch")

    dest = RDMUID(
        packet[3] << 8 | packet[4],
        (packet[5] << 24) | (packet[6] << 16) | (packet[7] << 8) | packet[8],
    )
    src = RDMUID(
        packet[9] << 8 | packet[10],
        (packet[11] << 24) | (packet[12] << 16) | (packet[13] << 8) | packet[14],
    )
    tn = packet[15]
    port_id_or_resp_type = packet[16]
    msg_count = packet[17]
    sub_device = (packet[18] << 8) | packet[19]
    cmd_class = packet[20]
    pid = (packet[21] << 8) | packet[22]
    pdl = packet[23]
    if 24 + pdl + 2 != len(packet):
        raise ValueError("parameter length mismatch")
    pdata = packet[24 : 24 + pdl]

    return RDMMessage(
        raw=packet,
        dest_uid=dest,
        src_uid=src,
        transaction_number=tn,
        command_class=cmd_class,
        parameter_id=pid,
        parameter_data=pdata,
        port_id_or_response_type=port_id_or_resp_type,
        message_count=msg_count,
        sub_device=sub_device,
    )


def decode_discovery_response(raw: bytes) -> Tuple[DiscoveryResult, Optional[RDMUID]]:
    if not raw:
        return (DiscoveryResult.NO_RESPONSE, None)

    try:
        aa_index = raw.index(0xAA)
    except ValueError:
        return (DiscoveryResult.COLLISION, None)

    data = raw[aa_index + 1 : aa_index + 1 + 16]
    if len(data) < 16:
        return (DiscoveryResult.COLLISION, None)

    decoded = bytearray()
    for i in range(0, 16, 2):
        b1 = data[i]
        b2 = data[i + 1]
        if (b1 & 0xAA) != 0xAA or (b2 & 0x55) != 0x55:
            return (DiscoveryResult.COLLISION, None)
        decoded.append(b1 & b2)

    uid_bytes = bytes(decoded[:6])
    checksum_bytes = bytes(decoded[6:8])
    expected = sum(uid_bytes) & 0xFFFF
    actual = (checksum_bytes[0] << 8) | checksum_bytes[1]
    if expected != actual:
        return (DiscoveryResult.COLLISION, None)

    uid = RDMUID(
        uid_bytes[0] << 8 | uid_bytes[1],
        (uid_bytes[2] << 24)
        | (uid_bytes[3] << 16)
        | (uid_bytes[4] << 8)
        | uid_bytes[5],
    )
    return (DiscoveryResult.VALID, uid)


@dataclass
class RDMPersonality:
    index: int
    dmx_footprint: int
    description: str = ""


@dataclass
class RDMDeviceInfo:
    uid: RDMUID
    rdm_protocol_version: int = 0x0100
    device_model_id: int = 0
    product_category: int = 0
    software_version_id: int = 0
    dmx_footprint: int = 0
    current_personality: int = 1
    personality_count: int = 1
    dmx_start_address: int = 1
    sub_device_count: int = 0
    sensor_count: int = 0
    manufacturer_label: str = ""
    device_model_description: str = ""
    device_label: str = ""
    software_version_label: str = ""
    supported_parameters: List[int] = field(default_factory=list)
    personalities: Dict[int, RDMPersonality] = field(default_factory=dict)
    identifying: bool = False


def parse_device_info_response(uid: RDMUID, data: bytes) -> RDMDeviceInfo:
    if len(data) < 19:
        raise ValueError("DEVICE_INFO response too short")
    info = RDMDeviceInfo(uid=uid)
    info.rdm_protocol_version = (data[0] << 8) | data[1]
    info.device_model_id = (data[2] << 8) | data[3]
    info.product_category = (data[4] << 8) | data[5]
    info.software_version_id = (
        (data[6] << 24) | (data[7] << 16) | (data[8] << 8) | data[9]
    )
    info.dmx_footprint = (data[10] << 8) | data[11]
    info.current_personality = data[12]
    info.personality_count = data[13]
    info.dmx_start_address = (data[14] << 8) | data[15]
    info.sub_device_count = (data[16] << 8) | data[17]
    info.sensor_count = data[18]
    return info


def parse_supported_parameters_response(data: bytes) -> List[int]:
    pids: List[int] = []
    for i in range(0, len(data) - 1, 2):
        pids.append((data[i] << 8) | data[i + 1])
    return pids
