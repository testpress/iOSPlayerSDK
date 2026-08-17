import Foundation

// Abstracts the heartbeat loop's delayed scheduling so PresenceHeartbeatManager
// can be unit tested with a fake that fires deterministically, without
// depending on a real run loop. Dispatch-based rather than Timer-based in the
// real implementation: a URLSession completion handler runs on a background
// queue with no active run loop, and Timer.scheduledTimer silently never
// fires when scheduled from one.
protocol PresenceScheduler {
    func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> PresenceCancellable
}

protocol PresenceCancellable {
    func cancel()
}

final class DispatchPresenceScheduler: PresenceScheduler {
    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(label: "com.tpstream.player.presence.heartbeat")) {
        self.queue = queue
    }

    func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> PresenceCancellable {
        let workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + max(seconds, 0), execute: workItem)
        return DispatchPresenceCancellable(workItem: workItem)
    }
}

private final class DispatchPresenceCancellable: PresenceCancellable {
    private let workItem: DispatchWorkItem

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem.cancel()
    }
}
