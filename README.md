# ScopeoInstrumenter
Objectives: 
* Benchmark an instrumenter that just exposes an API and make the difference with Pharo baseline
* Connect Scopeo's data capture mechanics that use the API
* Benchmark Scopeo's data capture mechanics and compare it with Pharo baseline and with the instrumenter that just exposes the API

The idea is that this API is exchangeable: Scopeo will work as long as the API is exposed.
Therefore one could explore possible optimizations by working on a more efficient backend providing the same API.

## Benchmark the mechanics to expose the API

Here, the benchmark code will be refered as `[benchmarkCode]`.

```Smalltalk
MetaLink uninstallAll.
dataInstrumented := OrderedCollection new.
instrumenter := ScopeoInstrumenter forPackages: (#(...list of package names (strings)...) collect: #asPackage).
instrumenter instrumentPackages.

50 timesRepeat: [ dataInstrumented add: ([ 1000 timesRepeat: [ benchmarkCode]] timeToRun) ].
instrumenter uninstall.
instrumenter := nil.
Smalltalk garbageCollect.
```

The collection `dataInstrumented` will contain the measures.

## Connect Scopeo

Look at the class `ScopeoInstrumenter`.
The two methods `traceAssignment:` and `traceSend:` expose the API data.
Put it in Scopeo's structure and collect it.

## Benchmark Scopeo's data capture based on the instrumentation back end

Repeat the benchmark code an instrumentation.
Do it in a new image.
