using NCDatasets, CairoMakie
using StackViews

struct IceDataset{T}
    paths::Vector{String}
    time::Int
    xrange::Tuple{Int,Int}
    yrange::Tuple{Int,Int}
    vars::Vector{String}
end


function IceDataset(
    dir;
    T = Float32,
    time = 1,
    xrange = (20, 80),
    yrange = (50, 100),
    vars = ["H_ice", "z_srf", "bmb", "uxy_s", "smb"],
)
    return IceDataset{T}(get_file_paths(dir), time, xrange, yrange, vars)
end

function features(d::IceDataset{T}, path::AbstractString) where {T}
    xmin, xmax = d.xrange
    ymin, ymax = d.yrange
    data = Array{T}(undef, xmax - xmin + 1, ymax - ymin + 1, length(d.vars))
    NCDataset(path) do ds
        for (i, var) in enumerate(d.vars)
            view(data, :, :, i) .= ds[var][xmin:xmax, ymin:ymax, d.time]
        end
    end
    return data
end
features(d::IceDataset, i::Int) = features(d, d.paths[i])
features(d::IceDataset, is::AbstractVector) = StackView(features.(Ref(d), is))

Base.getindex(d::IceDataset, i) = features(d, i)

is_nc(path) = endswith(path, "2D.nc")

function get_file_paths(path; recursive = true)
    netcdfs = String[]
    if isfile(path)
        is_nc(path) && push!(netcdfs, path)
    elseif isdir(path)
        if recursive
            for (root, _dirs, files) in walkdir(path)
                paths = joinpath.(root, files)
                append!(netcdfs, filter(is_nc, paths))
            end
        else # not recursive
            paths = readdir(path; join = true)
            append!(netcdfs, filter(is_nc, paths))
        end
    else
        error("$path must be a directory containing NetCDFs.")
    end

    isempty(netcdfs) && @warn("No NetCDFs found under $path.")
    return netcdfs
end

ids = IceDataset("data/sims/")
ids[1]
