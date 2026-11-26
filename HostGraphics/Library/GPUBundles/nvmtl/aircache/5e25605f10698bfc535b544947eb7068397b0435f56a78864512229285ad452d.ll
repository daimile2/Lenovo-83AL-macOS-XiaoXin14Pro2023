; ModuleID = 'nvmtl-air'
source_filename = "VTMTSComputeDirect_btp2_to_btp2"
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "air64_v28-apple-macosx26.7.0"

%struct.VTMTSDirectBlitterData = type { i8, i8, i8, i32, i32, i32, i32 }

@llvm.global_ctors = appending global [0 x { i32, ptr, ptr }] zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite)
define void @VTMTSComputeDirect_btp2_to_btp2(ptr addrspace(1) noundef readonly captures(none) "air-buffer-no-alias" %0, ptr addrspace(1) noundef writeonly captures(none) "air-buffer-no-alias" %1, ptr addrspace(2) noundef readonly align 4 captures(none) dereferenceable(20) "air-buffer-no-alias" %2, <2 x i16> noundef %3) local_unnamed_addr #0 {
  %5 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 5
  %6 = load i32, ptr addrspace(2) %5, align 4, !tbaa !23, !alias.scope !29, !noalias !32
  %7 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 6
  %8 = load i32, ptr addrspace(2) %7, align 4, !tbaa !35, !alias.scope !29, !noalias !32
  %9 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 4
  %10 = load i32, ptr addrspace(2) %9, align 4, !tbaa !36, !alias.scope !29, !noalias !32
  %11 = extractelement <2 x i16> %3, i64 0
  %12 = udiv i16 %11, 3
  %13 = shl nuw i16 %12, 1
  %14 = insertelement <2 x i16> %3, i16 %13, i64 0
  %15 = or i16 %13, 1
  %16 = insertelement <2 x i16> %3, i16 %15, i64 0
  %17 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 2
  %18 = load i8, ptr addrspace(2) %17, align 2, !tbaa !37, !range !38, !alias.scope !29, !noalias !32
  %19 = icmp eq i8 %18, 0
  %20 = shufflevector <2 x i16> %14, <2 x i16> poison, <2 x i32> <i32 1, i32 0>
  %21 = shufflevector <2 x i16> %16, <2 x i16> poison, <2 x i32> <i32 1, i32 0>
  %22 = select i1 %19, <2 x i16> %16, <2 x i16> %21
  %23 = select i1 %19, <2 x i16> %14, <2 x i16> %20
  %24 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 0
  %25 = load i8, ptr addrspace(2) %24, align 4, !tbaa !39, !range !38, !alias.scope !29, !noalias !32
  %26 = icmp eq i8 %25, 0
  br i1 %26, label %38, label %27

27:                                               ; preds = %4
  %28 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 3
  %29 = load i32, ptr addrspace(2) %28, align 4, !tbaa !40, !alias.scope !29, !noalias !32
  %30 = extractelement <2 x i16> %23, i64 0
  %31 = trunc i32 %29 to i16
  %32 = add i16 %31, -1
  %33 = sub i16 %32, %30
  %34 = insertelement <2 x i16> %23, i16 %33, i64 0
  %35 = extractelement <2 x i16> %22, i64 0
  %36 = sub i16 %32, %35
  %37 = insertelement <2 x i16> %22, i16 %36, i64 0
  br label %38

38:                                               ; preds = %27, %4
  %39 = phi <2 x i16> [ %37, %27 ], [ %22, %4 ]
  %40 = phi <2 x i16> [ %34, %27 ], [ %23, %4 ]
  %41 = getelementptr inbounds %struct.VTMTSDirectBlitterData, ptr addrspace(2) %2, i64 0, i32 1
  %42 = load i8, ptr addrspace(2) %41, align 1, !tbaa !41, !range !38, !alias.scope !29, !noalias !32
  %43 = icmp eq i8 %42, 0
  br i1 %43, label %53, label %44

44:                                               ; preds = %38
  %45 = extractelement <2 x i16> %40, i64 1
  %46 = trunc i32 %10 to i16
  %47 = add i16 %46, -1
  %48 = sub i16 %47, %45
  %49 = insertelement <2 x i16> %40, i16 %48, i64 1
  %50 = extractelement <2 x i16> %39, i64 1
  %51 = sub i16 %47, %50
  %52 = insertelement <2 x i16> %39, i16 %51, i64 1
  br label %53

53:                                               ; preds = %44, %38
  %54 = phi <2 x i16> [ %52, %44 ], [ %39, %38 ]
  %55 = phi <2 x i16> [ %49, %44 ], [ %40, %38 ]
  %56 = urem i16 %11, 3
  %57 = zext i16 %56 to i32
  switch i32 %57, label %123 [
    i32 0, label %58
    i32 1, label %72
    i32 2, label %86
  ]

58:                                               ; preds = %53
  %59 = extractelement <2 x i16> %55, i64 1
  %60 = zext i16 %59 to i32
  %61 = mul i32 %6, %60
  %62 = extractelement <2 x i16> %55, i64 0
  %63 = zext i16 %62 to i32
  %64 = lshr i32 %63, 1
  %65 = mul nuw nsw i32 %64, 3
  %66 = and i32 %63, 1
  %67 = add i32 %66, %61
  %68 = add i32 %67, %65
  %69 = zext i32 %68 to i64
  %70 = getelementptr inbounds i8, ptr addrspace(1) %0, i64 %69
  %71 = load i8, ptr addrspace(1) %70, align 1, !tbaa !42, !alias.scope !43, !noalias !44
  br label %123

72:                                               ; preds = %53
  %73 = extractelement <2 x i16> %54, i64 1
  %74 = zext i16 %73 to i32
  %75 = mul i32 %6, %74
  %76 = extractelement <2 x i16> %54, i64 0
  %77 = zext i16 %76 to i32
  %78 = lshr i32 %77, 1
  %79 = mul nuw nsw i32 %78, 3
  %80 = and i32 %77, 1
  %81 = add i32 %80, %75
  %82 = add i32 %81, %79
  %83 = zext i32 %82 to i64
  %84 = getelementptr inbounds i8, ptr addrspace(1) %0, i64 %83
  %85 = load i8, ptr addrspace(1) %84, align 1, !tbaa !42, !alias.scope !43, !noalias !44
  br label %123

86:                                               ; preds = %53
  %87 = extractelement <2 x i16> %55, i64 1
  %88 = zext i16 %87 to i32
  %89 = mul i32 %6, %88
  %90 = extractelement <2 x i16> %55, i64 0
  %91 = lshr i16 %90, 1
  %92 = zext i16 %91 to i32
  %93 = mul nuw nsw i32 %92, 3
  %94 = add i32 %89, 2
  %95 = add i32 %94, %93
  %96 = zext i32 %95 to i64
  %97 = getelementptr inbounds i8, ptr addrspace(1) %0, i64 %96
  %98 = load i8, ptr addrspace(1) %97, align 1, !tbaa !42, !alias.scope !43, !noalias !44
  %99 = zext i8 %98 to i16
  %100 = shl i16 %90, 2
  %101 = and i16 %100, 4
  %102 = lshr i16 %99, %101
  %103 = and i16 %102, 15
  %104 = extractelement <2 x i16> %54, i64 1
  %105 = zext i16 %104 to i32
  %106 = mul i32 %6, %105
  %107 = extractelement <2 x i16> %54, i64 0
  %108 = lshr i16 %107, 1
  %109 = zext i16 %108 to i32
  %110 = mul nuw nsw i32 %109, 3
  %111 = add i32 %106, 2
  %112 = add i32 %111, %110
  %113 = zext i32 %112 to i64
  %114 = getelementptr inbounds i8, ptr addrspace(1) %0, i64 %113
  %115 = load i8, ptr addrspace(1) %114, align 1, !tbaa !42, !alias.scope !43, !noalias !44
  %116 = zext i8 %115 to i16
  %117 = shl i16 %107, 2
  %118 = and i16 %117, 4
  %119 = lshr i16 %116, %118
  %120 = shl nuw nsw i16 %119, 4
  %121 = or i16 %120, %103
  %122 = trunc i16 %121 to i8
  br label %123

123:                                              ; preds = %86, %72, %58, %53
  %124 = phi i8 [ 0, %53 ], [ %122, %86 ], [ %85, %72 ], [ %71, %58 ]
  %125 = zext i16 %11 to i32
  %126 = extractelement <2 x i16> %3, i64 1
  %127 = zext i16 %126 to i32
  %128 = mul i32 %8, %127
  %129 = add i32 %128, %125
  %130 = zext i32 %129 to i64
  %131 = getelementptr inbounds i8, ptr addrspace(1) %1, i64 %130
  store i8 %124, ptr addrspace(1) %131, align 1, !tbaa !42, !alias.scope !45, !noalias !46
  ret void
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="32" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!air.version = !{!10}
!air.language_version = !{!11}
!air.compile_options = !{!12, !13, !14}
!air.kernel = !{!15}

!0 = !{i32 2, !"SDK Version", [3 x i32] [i32 26, i32 7, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 7, !"air.max_device_buffers", i32 31}
!4 = !{i32 7, !"air.max_constant_buffers", i32 31}
!5 = !{i32 7, !"air.max_threadgroup_buffers", i32 31}
!6 = !{i32 7, !"air.max_textures", i32 128}
!7 = !{i32 7, !"air.max_read_write_textures", i32 8}
!8 = !{i32 7, !"air.max_samplers", i32 16}
!9 = !{!"Apple metal version 32023.886 (metalfe-32023.886.1)"}
!10 = !{i32 2, i32 8, i32 0}
!11 = !{!"Metal", i32 4, i32 0, i32 0}
!12 = !{!"air.compile.denorms_disable"}
!13 = !{!"air.compile.fast_math_enable"}
!14 = !{!"air.compile.framebuffer_fetch_enable"}
!15 = !{ptr @VTMTSComputeDirect_btp2_to_btp2, !16, !17}
!16 = !{}
!17 = !{!18, !19, !20, !22}
!18 = !{i32 0, !"air.buffer", !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 1, !"air.arg_type_align_size", i32 1, !"air.arg_type_name", !"uchar", !"air.arg_name", !"srcBuffer"}
!19 = !{i32 1, !"air.buffer", !"air.location_index", i32 1, i32 1, !"air.read_write", !"air.address_space", i32 1, !"air.arg_type_size", i32 1, !"air.arg_type_align_size", i32 1, !"air.arg_type_name", !"uchar", !"air.arg_name", !"dstBuffer"}
!20 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 20, !"air.location_index", i32 2, i32 1, !"air.read", !"air.address_space", i32 2, !"air.struct_type_info", !21, !"air.arg_type_size", i32 20, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"VTMTSDirectBlitterData", !"air.arg_name", !"config"}
!21 = !{i32 0, i32 1, i32 0, !"bool", !"flipH", i32 1, i32 1, i32 0, !"bool", !"flipV", i32 2, i32 1, i32 0, !"bool", !"transpose", i32 4, i32 4, i32 0, !"uint", !"width", i32 8, i32 4, i32 0, !"uint", !"height", i32 12, i32 4, i32 0, !"uint", !"srcStride", i32 16, i32 4, i32 0, !"uint", !"dstStride"}
!22 = !{i32 3, !"air.thread_position_in_grid", !"air.arg_type_name", !"ushort2", !"air.arg_name", !"gid"}
!23 = !{!24, !28, i64 12}
!24 = !{!"_ZTS22VTMTSDirectBlitterData", !25, i64 0, !25, i64 1, !25, i64 2, !28, i64 4, !28, i64 8, !28, i64 12, !28, i64 16}
!25 = !{!"bool", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C++ TBAA"}
!28 = !{!"int", !26, i64 0}
!29 = !{!30}
!30 = distinct !{!30, !31, !"air-alias-scope-arg(2)"}
!31 = distinct !{!31, !"air-alias-scopes(VTMTSComputeDirect_btp2_to_btp2)"}
!32 = !{!33, !34}
!33 = distinct !{!33, !31, !"air-alias-scope-arg(0)"}
!34 = distinct !{!34, !31, !"air-alias-scope-arg(1)"}
!35 = !{!24, !28, i64 16}
!36 = !{!24, !28, i64 8}
!37 = !{!24, !25, i64 2}
!38 = !{i8 0, i8 2}
!39 = !{!24, !25, i64 0}
!40 = !{!24, !28, i64 4}
!41 = !{!24, !25, i64 1}
!42 = !{!26, !26, i64 0}
!43 = !{!33}
!44 = !{!34, !30}
!45 = !{!34}
!46 = !{!33, !30}
