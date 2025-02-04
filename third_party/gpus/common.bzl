load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")
load("@local_config_cuda//cuda:build_defs.bzl", "cuda_extra_copts")
load("@local_config_rocm//rocm:build_defs.bzl", "rocm_extra_copts")

def if_gpu(if_true, if_false = []):
    """Shorthand for select()'ing on whether we're building with gpu enabled
    Returns a select statement which evaluates to if_true if we're building
    with use_gpu enabled. Otherwise, the select statement evaluates to
    if_false.
    """
    return select({
        "//tools/platform:use_gpu": if_true,
        "//conditions:default": if_false,
    })

def if_cuda(if_true, if_false = []):
    return select({
        "@local_config_cuda//cuda:using_nvcc": if_true,
        "@local_config_cuda//cuda:using_clang": if_true,
        "//conditions:default": if_false,
    })

def if_rocm(if_true, if_false = []):
    return select({
        "@local_config_rocm//rocm:using_hipcc": if_true,
        "//conditions:default": if_false,
    })

def if_cuda_clang(if_true, if_false = []):
    return select({
        "@local_config_cuda//cuda:using_clang": if_true,
        "//conditions:default": if_false,
    })

def if_cuda_clang_opt(if_true, if_false = []):
    return select({
        "@local_config_cuda//cuda:using_clang_opt": if_true,
        "//conditions:default": if_false,
    })

def if_rocm_clang_opt(if_true, if_false = []):
    return select({
        "@local_config_rocm//rocm:using_clang_opt": if_true,
        "//conditions:default": if_false,
    })

def rocm_default_copts():
    return if_rocm(["-x", "hip"] +
                   rocm_extra_copts())
    +if_rocm_clang_opt(["-O3"])

def cuda_default_copts():
    return if_cuda([
                       "-x",
                       "cuda",
                       "-Xcuda-fatbinary=--compress-all",
                       "--no-cuda-include-ptx=all",
                   ] +
                   cuda_extra_copts())
    +if_cuda_clang_opt(["-O3"])

def gpu_default_copts():
    return cuda_default_copts() + rocm_default_copts()

def gpu_library(mandatory = True, copts = [], **kwargs):
    if mandatory:
        cc_library(copts = gpu_default_copts() + copts, linkstatic = True, **kwargs)
        cc_binary(
            name = "lib{}.so".format(kwargs["name"]),
            deps = [":{}".format(kwargs["name"])],
            linkshared = True,
            linkstatic = True,
            visibility = ["//visibility:public"],
            tags = ["export_library", kwargs["name"]],
        )
    else:
        cc_library(copts = gpu_default_copts() + copts, **kwargs)

def cuda_library(**kwargs):
    gpu_library(**kwargs)
