class DexGlucosePacket {
  // Todo: Finish implementing the Dexcom Glucose Packet constructor. Will be used to store constructor data in SharedPreferences in JSON format
  // Todo: Decide which parameters should be stored and which data is possibly irrelevant.
  // Todo: Find out what infiltered, filtered and sequence parameters mean
  int _statusRaw;
  int _glucoseRaw;
  double _glucose;
  int _clock;
  int _timestamp;
  int _unfiltered;
  int _filtered;
  int _sequence;
  bool _glucoseIsDisplayOnly; // default false
  int _state;
  double _trend;
  int _age;
  bool _valid;

  // All these fields are given and decoded like in XDrip
  // https://github.com/NightscoutFoundation/xDrip/blob/master/app/src/main/java/com/eveningoutpost/dexdrip/cgm/dex/g7/EGlucoseRxMessage.java
  DexGlucosePacket(
      this._statusRaw,
      this._glucoseRaw,
      this._glucose,
      this._clock,
      this._timestamp,
      this._unfiltered,
      this._filtered,
      this._sequence,
      this._glucoseIsDisplayOnly,
      this._state,
      this._trend,
      this._age,
      this._valid);

  // Getters
  int get statusRaw => _statusRaw;
  int get glucoseRaw => _glucoseRaw;
  double get glucose => _glucose;
  int get clock => _clock;
  int get timestamp => _timestamp;
  int get unfiltered => _unfiltered;
  int get filtered => _filtered;
  int get sequence => _sequence;
  bool get glucoseIsDisplayOnly => _glucoseIsDisplayOnly;
  int get state => _state;
  double get trend => _trend;
  int get age => _age;
  bool get valid => _valid;

// toJson Method
  Map<String, dynamic> toJson() {
    return {
      'statusRaw': _statusRaw,
      'glucoseRaw': _glucoseRaw,
      'glucose' : _glucose,
      'clock': _clock,
      'timestamp': _timestamp,
      'unfiltered': _unfiltered,
      'filtered': _filtered,
      'sequence': _sequence,
      'glucoseIsDisplayOnly': _glucoseIsDisplayOnly,
      'state': _state,
      'trend': _trend,
      'age': _age,
      'valid': _valid
    };
  }

  // fromJson Constructor
  factory DexGlucosePacket.fromJson(Map<String, dynamic> json) {
    return DexGlucosePacket(
      json['statusRaw'],
      json['glucoseRaw'],
      json['glucose'],
      json['clock'],
      json['timestamp'],
      json['unfiltered'],
      json['filtered'],
      json['sequence'],
      json['glucoseIsDisplayOnly'] ?? false, // Default to false if not provided
      json['state'],
      json['trend'],
      json['age'],
      json['valid'] ?? true, // Default to true if not provided
    );
  }
}
