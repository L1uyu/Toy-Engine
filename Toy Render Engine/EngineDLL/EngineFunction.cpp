#include "EngineFunction.h"

bool __stdcall Init(void)
{
	return EngineApp::GetApp()->Initialize();
}

int __stdcall Run(void)
{
	return EngineApp::GetApp()->Run();
}

