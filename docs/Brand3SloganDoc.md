> goerli示例:0xa23FDABA53adD78F09ea724F5c177F7281b3d90A

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
> 增加一个tag资源

***参数***

| 参数key    | 参数类型    | 参数解释         |
|----------|---------|--------------|
| creator  | address | nft的创造者      |
| splitter | address | nft版税的分账合约地址 |

***响应***
> 无
---