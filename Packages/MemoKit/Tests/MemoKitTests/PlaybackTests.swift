import Testing
@testable import MemoKit

@Suite struct PlaybackTests {
    @Test func skipSilenceKeepsSpeechAndDropsLongPauses() {
        let speech = [Float](repeating: 0.6, count: 50)
        let pause = [Float](repeating: 0.05, count: 100)
        let blip = [Float](repeating: 0.05, count: 10)
        let peaks = speech + pause + speech + blip + speech
        let ranges = Silence.voiced(peaks: peaks, duration: 5.2)
        #expect(ranges.count == 2)
        #expect(abs(ranges[0].upperBound - 1.15) < 0.001)
        #expect(abs(ranges[1].lowerBound - 2.85) < 0.001)
        #expect(ranges[1].upperBound == 5.2)
    }

    @Test func silentRecordingStillPlays() {
        #expect(Silence.voiced(peaks: [0, 0, 0], duration: 0.06) == [0..<0.06])
    }

    @Test func scheduleMapsPlayedTimeAcrossGaps() {
        let schedule = Schedule(segments: [0..<1, 3..<4])
        #expect(schedule.fileTime(afterPlaying: 0.5) == 0.5)
        #expect(schedule.fileTime(afterPlaying: 1.5) == 3.5)
        #expect(schedule.fileTime(afterPlaying: 9) == 4)
    }
}
