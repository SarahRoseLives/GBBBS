enum CommandGroup {
  BASIC(2),
  EXTENDED(10);

  const CommandGroup(this.value);
  final int value;
  static CommandGroup fromInt(int val) => CommandGroup.values.firstWhere((e) => e.value == val, orElse: () => CommandGroup.BASIC);
}

enum BasicCommand {
  UNKNOWN(0),
  GET_DEV_ID(1),
  SET_REG_TIMES(2),
  GET_REG_TIMES(3),
  GET_DEV_INFO(4),
  READ_STATUS(5),
  REGISTER_NOTIFICATION(6),
  CANCEL_NOTIFICATION(7),
  GET_NOTIFICATION(8),
  EVENT_NOTIFICATION(9),
  READ_SETTINGS(10),
  WRITE_SETTINGS(11),
  STORE_SETTINGS(12),
  READ_RF_CH(13),
  WRITE_RF_CH(14),
  GET_IN_SCAN(15),
  SET_IN_SCAN(16),
  SET_REMOTE_DEVICE_ADDR(17),
  GET_TRUSTED_DEVICE(18),
  DEL_TRUSTED_DEVICE(19),
  GET_HT_STATUS(20),
  SET_HT_ON_OFF(21),
  GET_VOLUME(22),
  SET_VOLUME(23),
  RADIO_GET_STATUS(24),
  RADIO_SET_MODE(25),
  RADIO_SEEK_UP(26),
  RADIO_SEEK_DOWN(27),
  RADIO_SET_FREQ(28),
  READ_ADVANCED_SETTINGS(29),
  WRITE_ADVANCED_SETTINGS(30),
  HT_SEND_DATA(31),
  SET_POSITION(32),
  READ_BSS_SETTINGS(33),
  WRITE_BSS_SETTINGS(34),
  FREQ_MODE_SET_PAR(35),
  FREQ_MODE_GET_STATUS(36),
  READ_RDA1846S_AGC(37),
  WRITE_RDA1846S_AGC(38),
  READ_FREQ_RANGE(39),
  WRITE_DE_EMPH_COEFFS(40),
  STOP_RINGING(41),
  SET_TX_TIME_LIMIT(42),
  SET_IS_DIGITAL_SIGNAL(43),
  SET_HL(44),
  SET_DID(45),
  SET_IBA(46),
  GET_IBA(47),
  SET_TRUSTED_DEVICE_NAME(48),
  SET_VOC(49),
  GET_VOC(50),
  SET_PHONE_STATUS(51),
  READ_RF_STATUS(52),
  PLAY_TONE(53),
  GET_DID(54),
  GET_PF(55),
  SET_PF(56),
  RX_DATA(57),
  WRITE_REGION_CH(58),
  WRITE_REGION_NAME(59),
  SET_REGION(60),
  SET_PP_ID(61),
  GET_PP_ID(62),
  READ_ADVANCED_SETTINGS2(63),
  WRITE_ADVANCED_SETTINGS2(64),
  UNLOCK(65),
  DO_PROG_FUNC(66),
  SET_MSG(67),
  GET_MSG(68),
  BLE_CONN_PARAM(69),
  SET_TIME(70),
  SET_APRS_PATH(71),
  GET_APRS_PATH(72),
  READ_REGION_NAME(73),
  SET_DEV_ID(74),
  GET_PF_ACTIONS(75),
  GET_POSITION(76);

  const BasicCommand(this.value);
  final int value;
  static BasicCommand fromInt(int val) => BasicCommand.values.firstWhere((e) => e.value == val, orElse: () => BasicCommand.UNKNOWN);
}

enum ExtendedCommand {
  UNKNOWN(0),
  GET_DEV_STATE_VAR(16387);

  const ExtendedCommand(this.value);
  final int value;
  static ExtendedCommand fromInt(int val) => ExtendedCommand.values.firstWhere((e) => e.value == val, orElse: () => ExtendedCommand.UNKNOWN);
}

enum EventType {
  UNKNOWN(0),
  HT_STATUS_CHANGED(1),
  DATA_RXD(2),
  NEW_INQUIRY_DATA(3),
  RESTORE_FACTORY_SETTINGS(4),
  HT_CH_CHANGED(5),
  HT_SETTINGS_CHANGED(6),
  RINGING_STOPPED(7),
  RADIO_STATUS_CHANGED(8),
  USER_ACTION(9),
  SYSTEM_EVENT(10),
  BSS_SETTINGS_CHANGED(11),
  DATA_TXD(12),
  POSITION_CHANGE(13);

  const EventType(this.value);
  final int value;
  static EventType fromInt(int val) =>
      EventType.values.firstWhere((e) => e.value == val, orElse: () => EventType.UNKNOWN);
}

enum PowerStatusType {
  UNKNOWN(0),
  BATTERY_LEVEL(1),
  BATTERY_VOLTAGE(2),
  RC_BATTERY_LEVEL(3),
  BATTERY_LEVEL_AS_PERCENTAGE(4);

  const PowerStatusType(this.value);
  final int value;
   static PowerStatusType fromInt(int val) =>
      PowerStatusType.values.firstWhere((e) => e.value == val, orElse: () => PowerStatusType.UNKNOWN);
}

enum ChannelType {
  OFF(0),
  A(1),
  B(2);

  const ChannelType(this.value);
  final int value;
  static ChannelType fromInt(int val) =>
      ChannelType.values.firstWhere((e) => e.value == val, orElse: () => ChannelType.OFF);
}

enum ReplyStatus {
  SUCCESS(0),
  NOT_SUPPORTED(1),
  NOT_AUTHENTICATED(2),
  INSUFFICIENT_RESOURCES(3),
  AUTHENTICATING(4),
  INVALID_PARAMETER(5),
  INCORRECT_STATE(6),
  IN_PROGRESS(7),
  FAILURE(255);

  const ReplyStatus(this.value);
  final int value;
  static ReplyStatus fromInt(int value) => ReplyStatus.values.firstWhere((e) => e.value == value, orElse: () => ReplyStatus.FAILURE);
}

enum ModulationType { FM, AM, DMR }
enum BandwidthType { NARROW, WIDE }