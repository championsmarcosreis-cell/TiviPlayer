package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import android.net.Uri;
import java.io.ByteArrayOutputStream;
import java.util.Collections;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public final class TransportStreamProbeTest {
  private static final int TS_PACKET_SIZE = 188;
  private static final int PAT_PID = 0x0000;
  private static final int PMT_PID = 0x0100;
  private static final int AUDIO_PID = 0x0101;
  private static final int VIDEO_PID = 0x0102;

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
  public void inspectSampleInfoDetectsHighTransportCadenceForSamsungGuard() {
    byte[] sample =
        createTransportStreamSampleWithVideo(
            0x0F, 0x1B, 0L, 1501L, 3002L, 4503L, 6004L);

    TransportStreamProbe.StreamInfo streamInfo =
        TransportStreamProbe.inspectSampleInfo(sample, sample.length);

    assertEquals(TransportStreamProbe.AudioProfile.AAC_ADTS, streamInfo.getAudioProfile());
    assertTrue(streamInfo.shouldDisableSamsungHardwareDecoding());
  }

  @Test
  public void inspectSampleInfoKeepsLowTransportCadenceOutOfSamsungGuard() {
    byte[] sample =
        createTransportStreamSampleWithVideo(
            0x0F, 0x1B, 0L, 9009L, 18018L, 27027L, 36036L);

    TransportStreamProbe.StreamInfo streamInfo =
        TransportStreamProbe.inspectSampleInfo(sample, sample.length);

    assertEquals(TransportStreamProbe.AudioProfile.AAC_ADTS, streamInfo.getAudioProfile());
    assertFalse(streamInfo.shouldDisableSamsungHardwareDecoding());
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

  @Test
  public void whitelistedStreamUsesTolerantVlcPlaybackProfile() {
    XiaomiDeviceQuirks.VlcPlaybackProfile profile =
        XiaomiDeviceQuirks.resolveVlcPlaybackProfile(
            Uri.parse("http://177.104.161.199:8080/marcos/123456/96"), null);

    assertEquals(2500, profile.getNetworkCachingMs());
    assertEquals(2500, profile.getLiveCachingMs());
    List<String> options = profile.createLibVlcOptions();
    assertTrue(options.contains("--network-caching=2500"));
    assertTrue(options.contains("--live-caching=2500"));
    assertFalse(options.contains("--clock-jitter=0"));
    assertFalse(options.contains("--clock-synchro=0"));
  }

  @Test
  public void aacAdtsTransportStreamUsesTolerantVlcPlaybackProfile() {
    XiaomiDeviceQuirks.VlcPlaybackProfile profile =
        XiaomiDeviceQuirks.resolveVlcPlaybackProfile(
            Uri.parse("http://177.104.161.199:8080/marcos/123456/120"),
            createStreamInfo(TransportStreamProbe.AudioProfile.AAC_ADTS));

    assertEquals(2500, profile.getNetworkCachingMs());
    assertEquals(2500, profile.getLiveCachingMs());
  }

  @Test
  public void nonAdtsTransportStreamKeepsDefaultVlcPlaybackProfile() {
    XiaomiDeviceQuirks.VlcPlaybackProfile profile =
        XiaomiDeviceQuirks.resolveVlcPlaybackProfile(
            Uri.parse("http://177.104.161.199:8080/marcos/123456/120"),
            createStreamInfo(TransportStreamProbe.AudioProfile.OTHER_AUDIO));

    assertEquals(1500, profile.getNetworkCachingMs());
    assertEquals(1500, profile.getLiveCachingMs());
  }

  private static byte[] withNoisePrefix(byte[] sample, int prefixLength) {
    byte[] prefixed = new byte[prefixLength + sample.length];
    System.arraycopy(sample, 0, prefixed, prefixLength, sample.length);
    return prefixed;
  }

  private static TransportStreamProbe.StreamInfo createStreamInfo(
      TransportStreamProbe.AudioProfile audioProfile) {
    return new TransportStreamProbe.StreamInfo(
        audioProfile, TransportStreamProbe.VideoFrameRateProfile.OTHER, Float.NaN, -1, -1);
  }

  private static byte[] createTransportStreamSample(int audioStreamType) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    outputStream.writeBytes(createPsiPacket(PAT_PID, createPatSection(PMT_PID), 0));
    outputStream.writeBytes(
        createPsiPacket(PMT_PID, createPmtSection(AUDIO_PID, audioStreamType, -1, -1), 1));
    outputStream.writeBytes(createNullPacket(2));
    outputStream.writeBytes(createNullPacket(3));
    outputStream.writeBytes(createNullPacket(4));
    return outputStream.toByteArray();
  }

  private static byte[] createTransportStreamSampleWithVideo(
      int audioStreamType, int videoStreamType, long... videoPtsValues) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    outputStream.writeBytes(createPsiPacket(PAT_PID, createPatSection(PMT_PID), 0));
    outputStream.writeBytes(
        createPsiPacket(
            PMT_PID, createPmtSection(AUDIO_PID, audioStreamType, VIDEO_PID, videoStreamType), 1));
    int continuityCounter = 2;
    for (long ptsValue : videoPtsValues) {
      outputStream.writeBytes(createPesPacket(VIDEO_PID, ptsValue, continuityCounter));
      continuityCounter = (continuityCounter + 1) & 0x0F;
    }
    while (continuityCounter <= 6) {
      outputStream.writeBytes(createNullPacket(continuityCounter));
      continuityCounter++;
    }
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

  private static byte[] createPmtSection(
      int audioPid, int audioStreamType, int videoPid, int videoStreamType) {
    boolean includeVideo = videoPid >= 0 && videoStreamType >= 0;
    byte[] section = new byte[includeVideo ? 26 : 21];
    section[0] = 0x02;
    section[1] = (byte) 0xB0;
    section[2] = (byte) (includeVideo ? 0x17 : 0x12);
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
    if (includeVideo) {
      section[17] = (byte) videoStreamType;
      section[18] = (byte) (0xE0 | ((videoPid >> 8) & 0x1F));
      section[19] = (byte) (videoPid & 0xFF);
      section[20] = (byte) 0xF0;
      section[21] = 0x00;
      section[22] = 0x00;
      section[23] = 0x00;
      section[24] = 0x00;
      section[25] = 0x00;
    } else {
      section[17] = 0x00;
      section[18] = 0x00;
      section[19] = 0x00;
      section[20] = 0x00;
    }
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

  private static byte[] createPesPacket(int pid, long ptsValue, int continuityCounter) {
    byte[] packet = createEmptyPacket(pid, true, continuityCounter);
    int payloadOffset = 4;
    byte[] ptsBytes = encodePts(ptsValue);
    packet[payloadOffset] = 0x00;
    packet[payloadOffset + 1] = 0x00;
    packet[payloadOffset + 2] = 0x01;
    packet[payloadOffset + 3] = (byte) 0xE0;
    packet[payloadOffset + 4] = 0x00;
    packet[payloadOffset + 5] = 0x00;
    packet[payloadOffset + 6] = (byte) 0x80;
    packet[payloadOffset + 7] = (byte) 0x80;
    packet[payloadOffset + 8] = 0x05;
    System.arraycopy(ptsBytes, 0, packet, payloadOffset + 9, ptsBytes.length);
    packet[payloadOffset + 14] = 0x00;
    return packet;
  }

  private static byte[] encodePts(long ptsValue) {
    byte[] pts = new byte[5];
    pts[0] = (byte) (((0x02 << 4) | (((ptsValue >> 30) & 0x07) << 1) | 0x01) & 0xFF);
    pts[1] = (byte) ((ptsValue >> 22) & 0xFF);
    pts[2] = (byte) (((((ptsValue >> 15) & 0x7F) << 1) | 0x01) & 0xFF);
    pts[3] = (byte) ((ptsValue >> 7) & 0xFF);
    pts[4] = (byte) ((((ptsValue & 0x7F) << 1) | 0x01) & 0xFF);
    return pts;
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
