#pragma once
#include "d3dUtil.h"
namespace LTCTexLoader {
	
	enum TexToUse {
		Inv_M,
		NF
	};

	HRESULT CreateLTCResources(
		ID3D12Device* device,
		ID3D12GraphicsCommandList* cmdList,
		LTCTexLoader::TexToUse texToUse,
		Microsoft::WRL::ComPtr<ID3D12Resource>& texture,
		Microsoft::WRL::ComPtr<ID3D12Resource>& textureUploadHeap
	);

};

