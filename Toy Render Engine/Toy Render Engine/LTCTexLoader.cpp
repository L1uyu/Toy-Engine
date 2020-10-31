#include "LTCTexLoader.h"
#include <iostream>



HRESULT LTCTexLoader::CreateLTCResources(
	ID3D12Device* device,
	ID3D12GraphicsCommandList* cmdList,
	LTCTexLoader::TexToUse texToUse,
	Microsoft::WRL::ComPtr<ID3D12Resource>& texture,
	Microsoft::WRL::ComPtr<ID3D12Resource>& textureUploadHeap
)
{
	

     
	float* g_ltc_1 = new float[4 * 64 * 64]();
	float* g_ltc_2 = new float[4 * 64 * 64]();
	
	UINT byteSize = 4 * 64 * 64 * sizeof(float);

	std::vector<char>ltcBuffer;
	ltcBuffer.resize(byteSize);

	std::ifstream readFile;
	readFile.open("LTCTex/g_ltc_1", std::ios::in | std::ios::binary);
	if (!readFile)
	{
		std::cout << "Error opening file" << std::endl;
		
	}

	readFile.read(ltcBuffer.data(), byteSize);
	memcpy(g_ltc_1, ltcBuffer.data(), byteSize);
	
	readFile.close();

	std::ifstream readFile1;
	readFile1.open("LTCTex/g_ltc_2", std::ios::in | std::ios::binary);
	if (!readFile1)
	{
		std::cout << "Error opening file" << std::endl;
		
	}
	readFile1.read(ltcBuffer.data(), byteSize);
	memcpy(g_ltc_2, ltcBuffer.data(), byteSize);

	readFile1.close();

	if (device == nullptr)
		return E_POINTER;
	

	UINT texWidth = 64;
	UINT texHeight = 64;
	UINT texRowPitch = texWidth * 4 * sizeof(float);

	D3D12_RESOURCE_DESC texDesc;
	//ZeroMemory(&texDesc, sizeof(D3D12_RESOURCE_DESC));
	texDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
	texDesc.Alignment = 0;
	texDesc.Width = texWidth;
	texDesc.Height = texHeight;
	texDesc.DepthOrArraySize = 1;
	texDesc.MipLevels = 1;
	texDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
	texDesc.SampleDesc.Count = 1;
	texDesc.SampleDesc.Quality = 0;
	texDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
	texDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

	HRESULT hr =  device->CreateCommittedResource(
		&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_DEFAULT),
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_COPY_DEST,
		nullptr,
		IID_PPV_ARGS(&texture)
	);
	ThrowIfFailed(hr);

	UINT64 uploadBufferSize = GetRequiredIntermediateSize(texture.Get(), 0, 1);

	hr = device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD),
			D3D12_HEAP_FLAG_NONE,
			&CD3DX12_RESOURCE_DESC::Buffer(uploadBufferSize),
			D3D12_RESOURCE_STATE_GENERIC_READ,
			nullptr,
			IID_PPV_ARGS(&textureUploadHeap));
	ThrowIfFailed(hr);

	UINT64 requiredSize = 0u;
	UINT   NumSubresources = 1u;  //我们只有一副图片，即子资源个数为1
	D3D12_PLACED_SUBRESOURCE_FOOTPRINT stTxtLayouts = {};
	UINT64 textureRowSizes = 0u;
	UINT   textureRowNum = 0u;

	D3D12_RESOURCE_DESC stDestDesc = texture->GetDesc();

	device->GetCopyableFootprints(&stDestDesc
		, 0
		, NumSubresources
		, 0
		, &stTxtLayouts
		, &textureRowNum
		, &textureRowSizes
		, &requiredSize);
	
	BYTE* pData = nullptr;
	hr = textureUploadHeap->Map(0, NULL, reinterpret_cast<void**>(&pData));
	ThrowIfFailed(hr);

	BYTE* pDestSlice = reinterpret_cast<BYTE*>(pData) + stTxtLayouts.Offset;
	//const BYTE* pSrcSlice;
	if (texToUse == LTCTexLoader::TexToUse::Inv_M)
	{
		const BYTE* pSrcSlice = reinterpret_cast<BYTE*>(g_ltc_1);
		for (UINT y = 0; y < textureRowNum; ++y)
		{
			memcpy(pDestSlice + static_cast<SIZE_T>(stTxtLayouts.Footprint.RowPitch) * y
				, pSrcSlice + static_cast<SIZE_T>(texRowPitch) * y
				, texRowPitch);
		}
	}
	else
	{
		const BYTE* pSrcSlice = reinterpret_cast<BYTE*>(g_ltc_2);
		for (UINT y = 0; y < textureRowNum; ++y)
		{
			memcpy(pDestSlice + static_cast<SIZE_T>(stTxtLayouts.Footprint.RowPitch) * y
				, pSrcSlice + static_cast<SIZE_T>(texRowPitch) * y
				, texRowPitch);
		}
	}
	

	textureUploadHeap->Unmap(0, NULL);

	//向命令队列发出从上传堆复制纹理数据到默认堆的命令
	CD3DX12_TEXTURE_COPY_LOCATION Dst(texture.Get(), 0);
	CD3DX12_TEXTURE_COPY_LOCATION Src(textureUploadHeap.Get(), stTxtLayouts);
	cmdList->CopyTextureRegion(&Dst, 0, 0, 0, &Src, nullptr);

	//设置一个资源屏障，同步并确认复制操作完成
	//直接使用结构体然后调用的形式
	D3D12_RESOURCE_BARRIER stResBar = {};
	stResBar.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	stResBar.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
	stResBar.Transition.pResource = texture.Get();
	stResBar.Transition.StateBefore = D3D12_RESOURCE_STATE_COPY_DEST;
	stResBar.Transition.StateAfter = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
	stResBar.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;

	cmdList->ResourceBarrier(1, &stResBar);

	delete[](g_ltc_1);
	delete[](g_ltc_2);

	return hr;
	

}


