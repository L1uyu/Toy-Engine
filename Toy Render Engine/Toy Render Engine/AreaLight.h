#pragma once
#include <DirectXMath.h>
#include <DirectXPackedVector.h>

struct AreaLight {
	DirectX::XMFLOAT3 position = { 0.0f, 5.0f, 14.99f };
	float width = 8.0f;    
	DirectX::XMFLOAT3 dir = { 0.0f, 0.0f, -1.0f };       
	float height = 8.0f;
	DirectX::XMFLOAT3 horizontal = { 1.0f, 0.0f, 0.0f };
	float lightColor = 10.0f;
};

