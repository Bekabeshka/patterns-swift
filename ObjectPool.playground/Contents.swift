import Foundation

//The object pool pattern is a creational design pattern. The main idea behind it is that first you
//create a set of objects (a pool), then you acquire & release objects from the pool, instead of
//constantly creating and releasing them. 👍

class Pool<T> {
    private let lockQueue = DispatchQueue(label: "pool.lock.queue")
    private let semaphore: DispatchSemaphore
    private var items: [T] = []
    
    init(_ items: [T]) {
        self.items = items
        self.items.reserveCapacity(items.count)
        self.semaphore = DispatchSemaphore(value: items.count)
    }
    
    func acquire() ->T? {
        if self.semaphore.wait(timeout: .distantFuture) == .success, !self.items.isEmpty {
            return self.lockQueue.sync {
                return self.items.remove(at: 0)
            }
        }
        return nil
    }
    
    func release(_ item: T) {
        self.lockQueue.sync {
            self.items.append(item)
            self.semaphore.signal()
        }
    }
}

let pool = Pool<String>(["a", "b", "c"])

let a = pool.acquire()
print("\(a ?? "n/a") acquired")
let b = pool.acquire()
print("\(b ?? "n/a") acquired")
let c = pool.acquire()
print("\(c ?? "n/a") acquired")

DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(2)) {
    if let item = b {
        pool.release(item)
    }
}

print("No more resource in the pool, blocking thread until...")
let x = pool.acquire()
print("\(x ?? "n/a") acquired again")
