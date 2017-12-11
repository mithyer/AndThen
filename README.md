# AndThen

## A tiny program to solve sequence or spawn action

You can use the defined class to do your action like this:

```
 (WorkAction {
     // work0
 } --> WorkAction {
     // work1
 } & WorkAction {
     // work2
 }).excute {
     // all work done
 } 
```
**\"-->\"** means **"then"**, **"&"** means **"and"**, precedence of "-->" is **lower** than "&". 

After work0 done, work1 and work2 will start together.


Or You can create your own action like this:

```
class MyAction: Action {
    func excute(_ doneCallback: @escaping () -> Void) {
        // do somthing
        doneCallback()
    }
}

let a0 = MyAction()
let a1 = MyAction()
(a0-->a1-->a0).excute {
  // sequence over
}
```

Besides, you can insert delay action to delay your work:

```
let action = a0-->DelayAction(1.0)-->a1
action.excute{}
// a1 will be delayed 1 second after a0 done
```

Or repeat your action:

```
(a0.repeat { count -> Bool in
    return count < 3  // this closure will be call before every excute in repeats, return false to stop repeat
} --> a1).excute{}
// a0 will repeat 3 times before a1 excute
```

All excute is **async**
