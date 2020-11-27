# ZWoC 2021 Project List

ZWoc is for Zihan Winter of Code, which is a GSoC-like WoC host by Liao Zihan. This is similar to GSoC, but it is no-paid. Actually, it is a virtual WoC only for Liao Zihan. 

To practice English skill and manage the roadmap of my render engine, I set up the virtual WoC and list To-do projects below. If you are interesting in any one, please contact me. 

Email: realzihan@foxmail.com

## 1. Encapsulate the Dx12 renderer

**Skill:** C++

Toy render engine has an unfinished DirectX12 renderer. That part has presented basic dx12 framework, but need to be encapsulated more efficient. 



---



## Toy Render Engine

这个项目立项之初是想记录下我学习龙书的进度，发挥下GitHub最原始的代码托管功能 :)

不过在学习的过程中，我有了完成一个自己的渲染引擎的想法。打算在龙书的内容外，再添加自己喜欢的实验性feature。当然现在龙书也没有看完，实验性feature也没想清楚。
一步一步来吧👍

#### 编译
使用Windows SDK和VS2019。
#### 完成情况
- [x] 基础框架 DX12初始化
- [x] 绘制基础的不透明几何体
- [x] 材质 PBR光照 平行光 点光源 聚光灯实现
- [x] LTC 面光源
- [x] 贴图 MSAA 4x
- [ ] 透明 混合
- [ ] 待续
#### 重构
第一次进行代码重构，修改了龙书的框架。将D3D部分和相关的类写进库，由App部分调用库。虽然依旧不合理。日后慢慢阅读其他项目的架构再进行重构。

##### 闲话

本地的git邮箱设置错了，这么多天的提交都没有记录到小绿格子上，我好心痛。
