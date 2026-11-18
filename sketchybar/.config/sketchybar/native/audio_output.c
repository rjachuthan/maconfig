// Prints the kind of the default audio output device:
//   bluetooth - Bluetooth / Bluetooth LE (AirPods, headsets, ...)
//   wired     - USB / Thunderbolt / FireWire / PCI devices, or headphones
//               plugged into the built-in jack
//   speaker   - anything else (built-in speakers, HDMI, AirPlay, virtual)

#include <CoreAudio/CoreAudio.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

static OSStatus get_prop(AudioObjectID obj, AudioObjectPropertySelector sel,
                         AudioObjectPropertyScope scope, UInt32 size, void *out) {
  AudioObjectPropertyAddress addr = {sel, scope, kAudioObjectPropertyElementMain};
  return AudioObjectGetPropertyData(obj, &addr, 0, NULL, &size, out);
}

static int is_headphone_jack(AudioDeviceID dev) {
  UInt32 source = 0;
  if (get_prop(dev, kAudioDevicePropertyDataSource, kAudioDevicePropertyScopeOutput,
               sizeof(source), &source) == noErr && source == 'hdpn')
    return 1;

  // Apple Silicon exposes the jack as its own "External Headphones" device
  CFStringRef name = NULL;
  if (get_prop(dev, kAudioObjectPropertyName, kAudioObjectPropertyScopeGlobal,
               sizeof(name), &name) != noErr || !name)
    return 0;
  int match = CFStringFind(name, CFSTR("Headphone"), kCFCompareCaseInsensitive).location
              != kCFNotFound;
  CFRelease(name);
  return match;
}

int main(void) {
  AudioDeviceID dev = kAudioObjectUnknown;
  UInt32 transport = 0;

  if (get_prop(kAudioObjectSystemObject, kAudioHardwarePropertyDefaultOutputDevice,
               kAudioObjectPropertyScopeGlobal, sizeof(dev), &dev) != noErr ||
      dev == kAudioObjectUnknown ||
      get_prop(dev, kAudioDevicePropertyTransportType, kAudioObjectPropertyScopeGlobal,
               sizeof(transport), &transport) != noErr) {
    puts("speaker");
    return 0;
  }

  switch (transport) {
    case kAudioDeviceTransportTypeBluetooth:
    case kAudioDeviceTransportTypeBluetoothLE:
      puts("bluetooth");
      break;
    case kAudioDeviceTransportTypeUSB:
    case kAudioDeviceTransportTypeThunderbolt:
    case kAudioDeviceTransportTypeFireWire:
    case kAudioDeviceTransportTypePCI:
      puts("wired");
      break;
    case kAudioDeviceTransportTypeBuiltIn:
      puts(is_headphone_jack(dev) ? "wired" : "speaker");
      break;
    default:
      puts("speaker");
  }
  return 0;
}
