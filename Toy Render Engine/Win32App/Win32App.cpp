#include "../EngineDLL/EngineApp.h"

#pragma comment(lib, "EngineDLL.lib")

extern "C" __declspec(dllimport) D3DInterface* getInstance(HINSTANCE hInstance);
extern "C"
{
	__declspec(dllimport) bool __stdcall Init(void);
}

extern "C"
{
	__declspec(dllimport) int __stdcall Run(void);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE prevInstance,
	PSTR cmdline, int showCmd)
{
	// Enable run-time memory check for debug builds.
#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	try
	{
		D3DInterface* theApp = getInstance(hInstance);
		if (!Init())
			return 0;

		return Run();
	}
	catch (DxException& e)
	{
		MessageBox(nullptr, e.ToString().c_str(), L"HR Failed", MB_OK);
		return 0;
	}
}