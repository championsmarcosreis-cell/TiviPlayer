package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayOutputStream;
import java.util.Collections;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public final class TransportStreamProbeTest {
  private static final int TS_PACKET_SIZE = 188;
  private static final int PAT_PID = 0x0000;
  private static final int PMT_PID = 0x0100;
  private static final int AUDIO_PID = 0x0101;

  @Test
  public void inspectSampleDetectsAacAdtsAudioInProgramMap() {
    byte[] sample = withNoisePrefix(createTransportStreamSample(0x0F), 17);

    TransportStreamProbe.AudioProfile profile =
        TransportStreamProbe.inspectSample(sample, sample.length);

    assertEquals(TransportStreamProbe.AudioProfile.AAC_ADTS, profile);
  }

  @Test
  public void inspectSampleDetectsOtherAudioWhenProgramMapHasNoAdts() {
    byte[] sample = createTransportStreamSample(0x03);

    TransportStreamProbe.AudioProfile profile =
        TransportStreamProbe.inspectSample(sample, sample.length);

    assertEquals(TransportStreamProbe.AudioProfile.OTHER_AUDIO, profile);
  }

  @Test
  public void nonWhitelistedStreamDoesNotFallbackByDefaultWhenNoDeviceQuirkApplies() {
    VideoAsset asset =
        VideoAsset.fromRemoteUrl(
            "http://177.104.161.199:8080/marcos/123456/98",
            VideoAsset.StreamingFormat.UNKNOWN,
            Collections.emptyMap(),
            null);

    assertFalse(asset.shouldUseVlcFallback());
  }

  @Test
  public void whitelistedStreamStillFallsBackWithoutCodecProbe() {
    VideoAsset asset =
        VideoAsset.fromRemoteUrl(
            "http://177.104.161.199:8080/marcos/123456/95",
            VideoAsset.StreamingFormat.UNKNOWN,
            Collections.emptyMap(),
            null);

    assertTrue(asset.shouldUseVlcFallback());
  }

  private static byte[] withNoisePrefix(byte[] sample, int prefixLength) {
    byte[] prefixed = new byte[prefixLength + sample.length];
    System.arraycopy(sample, 0, prefixed, prefixLength, sample.length);
    return prefixed;
  }

  private static byte[] createTransportStreamSample(int audioStreamType) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    outputStream.writeBytes(createPsiPacket(PAT_PID, createPatSection(PMT_PID), 0));
    outputStream.writeBytes(createPsiPacket(PMT_PID, createPmtSection(AUDIO_PID, audioStreamType), 1));
    outputStream.writeBytes(createNullPacket(2));
    outputStream.writeBytes(createNullPacket(3));
    outputStream.writeBytes(createNullPacket(4));
    return outputStream.toByteArray();
  }

  private static byte[] createPatSection(int pmtPid) {
    byte[] section = new byte[16];
    section[0] = 0x00;
    section[1] = (byte) 0xB0;
    section[2] = 0x0D;
    section[3] = 0x00;
    section[4] = 0x01;
    section[5] = (byte) 0xC1;
    section[6] = 0x00;
    section[7] = 0x00;
    section[8] = 0x00;
    section[9] = 0x01;
    section[10] = (byte) (0xE0 | ((pmtPid >> 8) & 0x1F));
    section[11] = (byte) (pmtPid & 0xFF);
    section[12] = 0x00;
    section[13] = 0x00;
    section[14] = 0x00;
    section[15] = 0x00;
    return section;
  }

  private static byte[] createPmtSection(int audioPid, int audioStreamType) {
    byte[] section = new byte[21];
    section[0] = 0x02;
    section[1] = (byte) 0xB0;
    section[2] = 0x12;
    section[3] = 0x00;
    section[4] = 0x01;
    section[5] = (byte) 0xC1;
    section[6] = 0x00;
    section[7] = 0x00;
    section[8] = (byte) (0xE0 | ((audioPid >> 8) & 0x1F));
    section[9] = (byte) (audioPid & 0xFF);
    section[10] = (byte) 0xF0;
    section[11] = 0x00;
    section[12] = (byte) audioStreamType;
    section[13] = (byte) (0xE0 | ((audioPid >> 8) & 0x1F));
    section[14] = (byte) (audioPid & 0xFF);
    section[15] = (byte) 0xF0;
    section[16] = 0x00;
    section[17] = 0x00;
    section[18] = 0x00;
    section[19] = 0x00;
    section[20] = 0x00;
    return section;
  }

  private static byte[] createPsiPacket(int pid, byte[] section, int continuityCounter) {
    byte[] packet = createEmptyPacket(pid, true, continuityCounter);
    int payloadOffset = 4;
    packet[payloadOffset] = 0x00;
    System.arraycopy(section, 0, packet, payloadOffset + 1, section.length);
    return packet;
  }

  private static byte[] createNullPacket(int continuityCounter) {
    return createEmptyPacket(0x1FFF, false, continuityCounter);
  }

  private static byte[] createEmptyPacket(int pid, boolean payloadStart, int continuityCounter) {
    byte[] packet = new byte[TS_PACKET_SIZE];
    packet[0] = 0x47;
    packet[1] = (byte) (((payloadStart ? 0x40 : 0x00) | ((pid >> 8) & 0x1F)) & 0xFF);
    packet[2] = (byte) (pid & 0xFF);
    packet[3] = (byte) (0x10 | (continuityCounter & 0x0F));
    for (int i = 4; i < packet.length; i++) {
      packet[i] = (byte) 0xFF;
    }
    return packet;
  }
}
