# Some cool stuff about Concurrency 😎
### I took this notes from Ray Wenderlich's modern concurrency book 

In a synchronous context, code runs in one execution thread on a single CPU core. You can imagine synchronous functions as cars on a single-lane road, each driving behind the one in front of it. Even if one vehicle has a higher priority, like an ambulance on duty, it cannot “jump over” the rest of the traffic and drive faster.

Asynchronous execution allows different pieces of the program to run in any order on one thread — and, sometimes, at the same time on multiple threads, depending on many different events like user input, network connections and more.

In an asynchronous context, it’s hard to tell the exact order in which functions run, especially when several asynchronous functions need to use the same thread. Just like driving on a road where you have stoplights and places where traffic needs to yield, functions must sometimes wait until it’s their turn to continue, or even stop until they get a green light to proceed.

## The modern Swift concurrency model
The new concurrency model is tightly integrated with the language syntax, the Swift runtime and Xcode. It abstracts away the notion of threads for the developer. Its key new features include:
A cooperative thread pool.
async/await syntax.
Structured concurrency.
Context-aware code compilation.
With this high-level overview behind you, you’ll now take a deeper look at each of these features.

### Async let syntax
```
do {
  async let files = try model.availableFiles()
  async let status = try model.status()
} catch {
  // handle error
}
```

An async let binding allows you to create a local constant that’s similar to the concept of `promises` in other languages.

To group concurrent bindings and extract their values, you have two options:
Group them in a collection, such as an array.
Wrap them in parentheses as a tuple and then destructure the result.

``` 
let (filesResult, statusResult) = try await (files, status)
```
## AsyncSequence & Intermediate Task

### Getting to know `asyncSecuene`

`AsyncSequence` is a `protocol` describing a sequence that can produce elements asynchronously. Its surface API is identical to the Swift standard library’s Sequence, with one difference: You need to await the next element, since it might not be immediately available, as it would in a regular Sequence

```
for try await item in asyncSequence {
  // Next item from `asyncSequence`
}
```

cd


### Manualy cancelling tasks
``` 
@State var downloadTask: Task<Void, Error>? 
downloadTask = Task { // async execution }

//code for cancelling the task, it could be executed on .onDisappear(...) for example

downloadTask?.cancel()
```

