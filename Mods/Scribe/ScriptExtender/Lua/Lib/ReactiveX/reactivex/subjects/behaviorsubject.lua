local Subject = Ext.Require("Lib/ReactiveX/reactivex/subjects/subject.lua")
local Observer = Ext.Require("Lib/ReactiveX/reactivex/observer.lua")
local util = Ext.Require("Lib/ReactiveX/reactivex/util.lua")

--- A Subject that tracks its current value. Provides an accessor to retrieve the most
--- recent pushed value, and all subscribers immediately receive the latest value.
--- @class BehaviorSubject : Subject
local BehaviorSubject = setmetatable({}, Subject)
BehaviorSubject.__index = BehaviorSubject
BehaviorSubject.__tostring = util.constant('BehaviorSubject')

--- Creates a new BehaviorSubject.
--- @param ... any - The initial values.
--- @return BehaviorSubject
function BehaviorSubject.create(...)
    local self = {
        observers = {},
        stopped = false
    }

    if select('#', ...) > 0 then
        self.value = util.pack(...)
    end

    return setmetatable(self, BehaviorSubject)
end

--- Creates a new Observer and attaches it to the BehaviorSubject. Immediately broadcasts the most
--- recent value to the Observer.
--- @param observerOrNext function|Observer - Called when the BehaviorSubject produces a value.
--- @param onError function? - Called when the BehaviorSubject terminates due to an error.
--- @param onCompleted function? - Called when the BehaviorSubject completes normally.
function BehaviorSubject:subscribe(observerOrNext, onError, onCompleted)
    local observer

    if util.isa(observerOrNext, Observer) then
        observer = observerOrNext --[[@as Observer]]
    else
        observer = Observer.create(observerOrNext, onError, onCompleted)
    end

    local subscription = Subject.subscribe(self, observer)

    if self.value then
        observer:onNext(util.unpack(self.value))
    end

    return subscription
end

--- Pushes zero or more values to the BehaviorSubject. They will be broadcasted to all Observers.
--- @generic T : any
--- @param ... T
function BehaviorSubject:onNext(...)
    self.value = util.pack(...)
    return Subject.onNext(self, ...)
end

--- Returns the last value emitted by the BehaviorSubject, or the initial value passed to the
--- constructor if nothing has been emitted yet.
--- @generic T : any 
--- @return T|nil
function BehaviorSubject:getValue()
    if self.value ~= nil then
        return util.unpack(self.value)
    end
end

BehaviorSubject.__call = BehaviorSubject.onNext

return BehaviorSubject
