> goerli地址：0xD656EcDd53f1051e61F4841B2c99dC3df4CEE913

# bytecode
[RoyaltySplitterBytecode.json](RoyaltySplitterBytecode.json)

# abi
[RoyaltySplitterAbi.json](RoyaltySplitterAbi.json)

---

# 构造方法

***接口描述***
> 部署nft版税的分账合约

***参数***

| 参数key   | 参数类型      | 参数解释    |
|---------|-----------|---------|
| _payees | address[] | 支付的地址集合 |
| _shares | uint256[] | 支付的比例配置 |

***响应***
> 无
---

# release

***接口描述***
> 从合约中提取金额

***参数***

| 参数key   | 参数类型    | 参数解释       |
|---------|---------|------------|
| account | address | 要提取金额的账户地址 |

***响应***
> 无
---

# release

***接口描述***
> 从合约中提取金额

***参数***

| 参数key   | 参数类型    | 参数解释          |
|---------|---------|---------------|
| token   | IERC20  | IERC20代币的合约地址 |
| account | address | 要提取金额的账户地址    |

***响应***
> 无
---