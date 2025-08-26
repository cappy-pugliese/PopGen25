
using Distributions


function WrightFisher(N,p,t)
    g=1
    freqs=Float64[]
    append!(freqs,p)
    while g<t
        next = only(rand(Binomial(N,freqs[g]),1)/N)
        append!(freqs,next)
        g += 1
    end
    return(freqs)
end


function WrightFisher_long(N,p)
    freqs=Float64[]
    append!(freqs,p)
    while last(freqs)*(1-last(freqs)) > 0
        next = only(rand(Binomial(N,last(freqs)),1)/N)
        append!(freqs,next)
    end
    return(freqs)
end

function fake_alignment(n,L;gaps=false)
    if gaps
        geno_matrix = rand([missing,"A","T","C","G"],n,L)
    else
        geno_matrix = rand(["A","T","C","G"],n,L)
    end
    return(geno_matrix)
end

function is_segregating(allele)
    if(length(unique(allele))>1)
        return(true)
    else
        return(false)
    end
end

function fake_alignment_biallelic(ancestral::Matrix{String},n::Int64;gaps=0)
   alignment = repeat(ancestral,n)
   sfs_rates = [1/i for i in 1:n]
   sfs_rates = sfs_rates ./ sum(sfs_rates)
   mutation_rates = rand(Categorical(sfs_rates),size(ancestral)[2])/n
   mutations =  reduce(hcat,[rand(Bernoulli(mutation_rates[i]),n) for i in 1:size(ancestral)[2]])
   gaps = rand(Bernoulli(gaps),size(alignment))
   alt_alleles = [rand(setdiff(["A","T","C","G"],[x]),1) for x in ancestral]
   for i in 1:length(ancestral)
        alignment[findall(mutations[:,i]),i] .= alt_alleles[i]
        alignment[findall(gaps[:,i]),i] .= "-"
   end
   return(alignment)
end


function only_segregating(gm)
    idx = findall([is_segregating(i) for i in eachcol(gm)])
    return(gm[:,idx])
end

function geno_mat_to_Int(gm)
    geno_mat = zeros(size(gm))
    for i in 1:size(gm)[2]
        cases = unique(gm[:,i])
        rep = Dict(cases[x]=>x for x in 1:length(cases))
        geno_mat[:,i] = [rep[x] for x in gm[:,i]] 
    end
    return(geno_mat)
end

function scaled_loadings(PCA)
    scaled_loadings = loadings(PCA).*transpose(principalvars(PCA).^0.5)
    return(scaled_loadings)
end

function broken_stick_dist(r,n)
    1/n*sum([1/(n-i+1) for i in 1:r])
end

function broken_stick_pca(pca)
    prinvars = principalvars(pca)/sum(principalvars(pca))
    vals = [broken_stick_dist(i,length(prinvars)) for i in 1:length(prinvars)]
    sig_pcs = findfirst((vals .- prinvars) .< 0)-1
    return(reverse(vals), sig_pcs)
end

function scree(pca;broken_stick=false)
    prinvars = principalvars(pca)/sum(principalvars(pca))
    ret_plot = bar(prinvars,xlabel="PC",ylabel="Variance explained",legend=false)
    if broken_stick
        vals, sig_pcs = broken_stick_pca(pca)
        scatter!(ret_plot,vals,marker_z=reduce(vcat,[ones(sig_pcs),zeros(length(prinvars)-sig_pcs)]))
    end
    return(ret_plot)
end