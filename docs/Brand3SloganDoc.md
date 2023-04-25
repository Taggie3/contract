> goerli示例:0xDACF2788245BD029CDdAf14dc5084fde60F286b0
> mumbai地址：0xf15d5A35432F6e4954555B5f2bDAf3751a05b095

# bytecode

[Brand3SloganBytecode.json](Brand3SloganBytecode.json)

# abi

[Brand3SloganAbi.json](Brand3SloganAbi.json)

---

# 构造方法

***接口描述***
> 部署slogan合约时的构造方法

***参数***

| 参数key    | 参数类型   | 参数解释                 |
|----------|--------|----------------------|
| baseURI  | string | nft的metadata的基础访问uri |
| _name    | string | slogan的名称            |
| _symbol  | string | slogan的别名            |
| _logoUrl | string | slogan的logo地址        |

***响应***
> 无
---

# updateLogo

***接口描述***
> 更新slogan的logo

***参数***

| 参数key    | 参数类型   | 参数解释        |
|----------|--------|-------------|
| _logoUrl | string | 要更新的logo的地址 |

***响应***
> 无
---

# mint

***接口描述***
> 增加一个post资源

***参数***

| 参数key    | 参数类型    | 参数解释         |
|----------|---------|--------------|
| creator  | address | nft的创造者      |
| splitter | address | nft版税的分账合约地址 |

***响应***
> 无
---