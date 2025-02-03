using PythonCall
using Pyehtim
using Tables


@testset "extract_table ehtim" begin

    println("ehtim:")

    obs = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../test_data.uvfits"))

    obsavg = scan_average(obs)
    obsavg.add_cphase(snrcut=3, count="min")
    obsavg.add_amp()
    obsavg.add_logcamp(snrcut=3, count="min")

    obspol = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../../examples/Data/polarized_gaussian_withgains_withdterms_withfr.uvfits"); polrep="circ")
    obspolavg = scan_average(obspol)


    vis1 = Comrade.extract_vis(obsavg)
    vis  = extract_table(obsavg, Visibilities())
    @test vis[:measurement] ≈ vis1[:measurement]
    @test vis[:noise] ≈ vis1[:noise]
    @test vis[:baseline] == vis1[:baseline]
    mwn = measwnoise.(datatable(vis))
    @test real.(vis[:measurement]) ≈ getproperty.(real.(mwn), :val)
    @test imag.(vis[:measurement]) ≈ getproperty.(imag.(mwn), :val)
    @test vis[:noise] ≈ getproperty.(real.(mwn), :err)
    @test vis[:noise] ≈ getproperty.(imag.(mwn), :err)
    plotfields(vis, :U, :V)
    baselineplot(vis, :, uvdist, measwnoise; error=true)
    Plots.plot(vis)
    show(vis)

    amp1 = Comrade.extract_amp(obsavg)
    amp = extract_table(obsavg, VisibilityAmplitudes())
    @test amp[:measurement] ≈ amp1[:measurement]
    @test amp[:noise] ≈ amp1[:noise]
    @test amp[:baseline] == amp1[:baseline]
    mwn = measwnoise.(datatable(amp))
    @test amp[:measurement] ≈ getproperty.((mwn), :val)
    @test amp[:noise] ≈ getproperty.((mwn), :err)
    baselineplot(amp, :, uvdist, measwnoise, error=true)
    plotfields(amp, :U, :V)
    Plots.plot(amp)
    show(amp)

    cphase1 = Comrade.extract_cphase(obsavg; snrcut=3.0)
    cphase = extract_table(obsavg, ClosurePhases(;snrcut=3.0))
    @test cphase[:measurement] ≈ cphase1[:measurement]
    @test cphase[:noise] ≈ cphase1[:noise]
    @test cphase[:baseline] == cphase1[:baseline]
    mwn = measwnoise.(datatable(cphase))
    @test cphase[:measurement] ≈ getproperty.((mwn), :val)
    @test sqrt.(Array(diag(cphase[:noise]))) ≈ getproperty.((mwn), :err)
    baselineplot(cphase, :, uvdist, measwnoise, error=true)
    plotfields(cphase, :uvdist, :measurement)
    Plots.plot(cphase)
    show(cphase)


    lcamp1 = Comrade.extract_lcamp(obsavg; snrcut=3.0)
    lcamp  = extract_table(obsavg, LogClosureAmplitudes(;snrcut=3.0))
    @test lcamp[:measurement] ≈ lcamp1[:measurement]
    @test lcamp[:noise] ≈ lcamp1[:noise]
    @test lcamp[:baseline] == lcamp1[:baseline]
    mwn = measwnoise.(datatable(lcamp))
    @test lcamp[:measurement] ≈ getproperty.((mwn), :val)
    @test sqrt.(Array(diag(lcamp[:noise]))) ≈ getproperty.((mwn), :err)
    baselineplot(lcamp, :, uvdist, measwnoise, error=true)
    plotfields(lcamp, :uvdist, :measurement)
    Plots.plot(lcamp)
    show(lcamp)

    dcoh1 = Comrade.extract_coherency(obspolavg)
    dcoh  = extract_table(obspolavg, Coherencies())
    @test dcoh[:measurement].:1 ≈ dcoh1[:measurement].:1
    @test dcoh[:noise].:1 ≈ dcoh1[:noise].:1
    @test dcoh[:baseline] == dcoh1[:baseline]
    mwn = measwnoise.(datatable(dcoh))
    @test real.(dcoh[:measurement].:1) ≈ getproperty.(real.(mwn.:1), :val)
    @test imag.(dcoh[:measurement].:1) ≈ getproperty.(imag.(mwn.:1), :val)
    @test dcoh[:noise].:1 ≈ getproperty.(real.(mwn.:1), :err)
    @test dcoh[:noise].:1 ≈ getproperty.(imag.(mwn.:1), :err)
    @test real.(dcoh[:measurement].:2) ≈ getproperty.(real.(mwn.:2), :val)
    @test imag.(dcoh[:measurement].:2) ≈ getproperty.(imag.(mwn.:2), :val)
    @test dcoh[:noise].:2 ≈ getproperty.(real.(mwn.:2), :err)
    @test dcoh[:noise].:2 ≈ getproperty.(imag.(mwn.:2), :err)
    @test real.(dcoh[:measurement].:3) ≈ getproperty.(real.(mwn.:3), :val)
    @test imag.(dcoh[:measurement].:3) ≈ getproperty.(imag.(mwn.:3), :val)
    @test dcoh[:noise].:3 ≈ getproperty.(real.(mwn.:3), :err)
    @test dcoh[:noise].:3 ≈ getproperty.(imag.(mwn.:3), :err)
    @test real.(dcoh[:measurement].:4) ≈ getproperty.(real.(mwn.:4), :val)
    @test imag.(dcoh[:measurement].:4) ≈ getproperty.(imag.(mwn.:4), :val)
    @test dcoh[:noise].:4 ≈ getproperty.(real.(mwn.:4), :err)
    @test dcoh[:noise].:4 ≈ getproperty.(imag.(mwn.:4), :err)

    baselineplot(dcoh, :, uvdist, x->measwnoise(x)[1,1], error=true)
    Plots.plot(dcoh)
    show(dcoh)
end

@testset "EHTObservationTable" begin

    obs = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../test_data.uvfits"))
    obsavg = scan_average(obs)
    obsavg.add_amp(;debias=false)

    vis, amp, cphase, lcamp = extract_table(obsavg, Visibilities(), VisibilityAmplitudes(), ClosurePhases(), LogClosureAmplitudes())

    obspol = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../../examples/Data/polarized_gaussian_withgains_withdterms_withfr.uvfits"); polrep="circ")
    obspolavg = scan_average(obspol)
    dcoh = extract_table(obspolavg, Coherencies())

    @testset "Operations" begin
        visn = add_fractional_noise(vis, 0.01)
        @test visn[:measurement] ≈ vis[:measurement]
        @test visn[:noise] ≈ hypot.(vis[:noise], 0.01 .* abs.(vis[:measurement]))

        cohn = add_fractional_noise(dcoh, 0.01)
        @test cohn[:measurement] ≈ dcoh[:measurement]
        @test cohn[:noise].:1 ≈ hypot.(dcoh[:noise].:1, 0.01 .* abs.(tr.(dcoh[:measurement]))/2)
        @test cohn[:noise].:2 ≈ hypot.(dcoh[:noise].:2, 0.01 .* abs.(tr.(dcoh[:measurement]))/2)
        @test cohn[:noise].:3 ≈ hypot.(dcoh[:noise].:3, 0.01 .* abs.(tr.(dcoh[:measurement]))/2)
        @test cohn[:noise].:4 ≈ hypot.(dcoh[:noise].:4, 0.01 .* abs.(tr.(dcoh[:measurement]))/2)

        visflg = flag(x->uvdist(x) < 0.1e9, vis)
        visfil = filter(x->uvdist(x) < 0.1e9, vis)
        @test visflg.config.bandwidth == vis.config.bandwidth
        @test visflg.config.dec == vis.config.dec
        @test visflg.config.ra == vis.config.ra
        @test visflg.config.mjd == vis.config.mjd
        @test visflg.config.scans == vis.config.scans
        @test visflg.config.tarr == vis.config.tarr
        @test visflg.config.timetype == vis.config.timetype
        dtvis = datatable(vis)
        @test dtvis[uvdist.(dtvis) .>= 0.1e9] == datatable(visflg)
    end

    @testset "Dirty stuff" begin
        dbeam = dirty_beam(μas2rad(150.0), 256, vis)
        dimg = dirty_image(μas2rad(150.0), 256, vis)
    end

    @test vis[:measurement] == Comrade.measurement(vis)
    @test vis[:noise] == Comrade.noise(vis)
    @test firstindex(vis) == 1
    @test lastindex(vis) == length(vis)
    @test vis[1] isa Comrade.datumtype(vis)
    @test vis[1:10] isa Comrade.EHTObservationTable
    @test @view(vis[1:10]) isa Comrade.EHTObservationTable

    @test vis[1] isa Comrade.EHTVisibilityDatum
    @test Tables.istable(typeof(vis))
    @test Tables.columnaccess(typeof(vis))
    @test Tables.columns(vis) == datatable(vis)
    @test Tables.getcolumn(vis, 1) == Comrade.measurement(vis)
    @test lastindex(vis) == length(Comrade.measurement(vis))
    @test firstindex(vis) == 1

    @test beamsize(vis) == beamsize(arrayconfig(vis))

    show(IOBuffer(), arrayconfig(vis))


    @test amp[:measurement] == Comrade.measurement(amp)
    @test amp[:noise] == Comrade.noise(amp)
    @test firstindex(amp) == 1
    @test lastindex(amp) == length(amp)
    @test amp[1] isa Comrade.datumtype(amp)
    @test Comrade.measurement(amp[1]) == Comrade.measurement(amp)[1]
    @test Comrade.noise(amp[1]) == Comrade.noise(amp)[1]
    @test VLBISkyModels.polarization(amp[1]) == :I



    @test arrayconfig(cphase)|>arrayconfig|>datatable == arrayconfig(lcamp)|>arrayconfig|>datatable
    @test arrayconfig(vis)|>datatable == arrayconfig(lcamp)|>arrayconfig|>datatable
    @test arrayconfig(amp)|>datatable == arrayconfig(lcamp)|>arrayconfig|>datatable


    @test length(vis) == length(obsavg.data)
    @test length(amp) == length(obsavg.amp)
    @test Comrade.amplitudes(vis.measurement, arrayconfig(amp)) ≈ amp.measurement

    println("observation: ")
    @test domain(vis) == domain(arrayconfig(vis))
    @test domain(amp) == domain(arrayconfig(amp))
    @test domain(cphase) == domain(arrayconfig(cphase))
    @test domain(lcamp) == domain(arrayconfig(lcamp))
    @test domain(lcamp; executor=ThreadsEx()) == domain(arrayconfig(lcamp); executor=ThreadsEx())

    @test baseline(vis[1]) == baseline(vis)[1]
    @test baseline(amp[1]) == baseline(amp)[1]
    @test baseline(cphase[1]) == baseline(cphase)[1]
    @test baseline(lcamp[1])  == baseline(lcamp)[1]

    #Test amplitude which is already debiased for very very dumb reasons
    @test sqrt.(abs2.(vis.measurement)) ≈ amp.measurement
    ac = arrayconfig(vis)
    Plots.plot(ac)
    plotfields(vis, :U, :V)

    d = Comrade.domain(ac)
    m = modify(Gaussian(), Stretch(μas2rad(40.0)))
    @test length(visibilitymap(m, d)) == length(ac)

    @testset "Closures" begin
        show(arrayconfig(cphase))
        @test propertynames(arrayconfig(cphase)) == propertynames(arrayconfig(vis))
        @test size(Comrade.designmat(arrayconfig(cphase)), 2) == length(vis)
        @test size(Comrade.designmat(arrayconfig(cphase)), 1) == length(cphase)
        @test sites(cphase) == sites(arrayconfig(cphase))
        @test sites(cphase) == sites(vis)
        @test Comrade.closure_phases(vis.measurement, Comrade.designmat(arrayconfig(cphase))) ≈ cphase.measurement
        @test Comrade.factornoisecovariance(arrayconfig(cphase)) ≈ Comrade.VLBILikelihoods.CholeskyFactor(cphase[:noise])
        @test firstindex(cphase) == 1
        @test lastindex(cphase) == length(cphase)
        @test cphase[1] isa Comrade.datumtype(cphase)
        @test length(Comrade.triangle(cphase[1])) == 3
        @test cphase[1:10] isa Comrade.EHTObservationTable
        @test @view(cphase[1:10]) isa Comrade.EHTObservationTable



        @test propertynames(arrayconfig(lcamp)) == propertynames(arrayconfig(vis))
        @test size(Comrade.designmat(arrayconfig(lcamp)), 2) == length(vis)
        @test size(Comrade.designmat(arrayconfig(lcamp)), 1) == length(lcamp)
        @test sites(lcamp) == sites(arrayconfig(lcamp))
        @test sites(lcamp) == sites(vis)
        @test Comrade.logclosure_amplitudes(vis.measurement, Comrade.designmat(arrayconfig(lcamp))) ≈ lcamp.measurement
        @test Comrade.factornoisecovariance(arrayconfig(lcamp)) ≈ Comrade.VLBILikelihoods.CholeskyFactor(lcamp[:noise])
        @test firstindex(lcamp) == 1
        @test lastindex(lcamp) == length(lcamp)
        @test lcamp[1] isa Comrade.datumtype(lcamp)
        @test length(Comrade.quadrangle(lcamp[1])) == 4

        ac = arrayconfig(cphase)
        @test ac[1] isa NTuple{3, Comrade.EHTArrayBaselineDatum}
        @test firstindex(ac) == 1
        @test lastindex(ac) == length(cphase)
        @test beamsize(ac) == beamsize(cphase)
        @test @view(ac[1:10]) isa Comrade.ClosureConfig
        @test (ac[1:10]) isa Comrade.ClosureConfig


    end

    @testset "Coherencies" begin
        obs = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../test_data.uvfits"), polrep="circ")
        obsavg = scan_average(obs)

        coh = extract_table(obsavg, Coherencies())
        @test coh[:measurement].:1 == Comrade.measurement(coh).:1

        @test coh[:noise].:1 == Comrade.noise(coh).:1
        @test firstindex(coh) == 1
        @test lastindex(coh) == length(coh)
        @test coh[1] isa Comrade.datumtype(coh)
        @test VLBISkyModels.polarization(coh[1]) == (CirBasis(), CirBasis())

    end
end


@testset "TimeTable" begin

    @testset "Visibilities" begin
        obs = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../test_data.uvfits"))

        obsavg = scan_average(obs)

        vis = extract_table(obsavg, Visibilities())
        ttab = timetable(vis)
        @test length(ttab) == length(arrayconfig(vis).scans)
        @test firstindex(ttab) == 1
        @test lastindex(ttab) == length(ttab)
        eachindex(ttab)
        @test ttab[1] isa Comrade.Scan
        @test length(ttab[1:2]) == 2
        @test eltype(ttab[1:2]) <: Comrade.Scan


        scan = ttab[10]
        @test scan[1] isa Comrade.EHTVisibilityDatum
        first(ttab)
        last(ttab)
        bl = baseline(scan)
        s = sites(scan)
        @test s == sort(unique(vcat(bl...)))
        show(scan)
        @test scan[:measurement] == @view measurement(vis)[scan.index[2]:scan.index[3]]
        @test scan[:noise] == @view noise(vis)[scan.index[2]:scan.index[3]]
        @test scan[:baseline] == @view vis[:baseline][scan.index[2]:scan.index[3]]
    end

    @testset "coherencies" begin
        obs = ehtim.obsdata.load_uvfits(joinpath(@__DIR__, "../test_data.uvfits"), polrep="circ")

        obsavg = scan_average(obs)

        vis = extract_table(obsavg, Coherencies())
        ttab = timetable(vis)
        @test length(ttab) == length(arrayconfig(vis).scans)
        @test firstindex(ttab) == 1
        @test lastindex(ttab) == length(ttab)
        eachindex(ttab)
        @test ttab[1] isa Comrade.Scan
        @test length(ttab[1:2]) == 2
        @test eltype(ttab[1:2]) <: Comrade.Scan


        scan = ttab[10]
        bl = baseline(scan)
        s = sites(scan)
        @test s == sort(unique(vcat(bl...)))
        show(scan)
        @test scan[:measurement] == @view measurement(vis)[scan.index[2]:scan.index[3]]
        @test scan[:noise] == @view noise(vis)[scan.index[2]:scan.index[3]]
        @test scan[:baseline] == @view vis[:baseline][scan.index[2]:scan.index[3]]
    end
end
