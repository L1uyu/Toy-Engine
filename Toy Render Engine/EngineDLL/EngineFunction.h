#pragma once
#include "EngineApp.h"


extern "C" __declspec(dllexport) D3DInterface* getInstance(HINSTANCE hInstance)
{
	D3DInterface* pInstance = new EngineApp(hInstance);
	return pInstance;
}
extern "C"
{
	__declspec(dllexport) bool __stdcall Init(void);
}

extern "C"
{
	__declspec(dllexport) int __stdcall Run(void);
}


