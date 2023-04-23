> goerli地址：0x560e62f6D61FeF04D02aDcaFE1D86881D3052aE4

# bytecode
[Brand3TagBytecode.json](Brand3TagBytecode.json)

# abi
[Brand3TagAbi.json](Brand3TagAbi.json)

# mint

***接口描述***
> 增加一个tag资源

***参数***

| 参数key     | 参数类型   | 参数解释   |
|-----------|--------|--------|
| tagValue  | string | tag的内容 |
| tagTypes  | string | tag的类型 |

***响应***
> 无
---

# tagValueToExist

***接口描述***
> 判断tag的内容是否已存在

***参数***

| 参数key    | 参数类型   | 参数解释   |
|----------|--------|--------|
| tagValue | string | tag的内容 |

***响应***

| 响应类型 | 响应解释       |
|------|------------|
| bool | tag内容是否已存在 |

---

# tokenIdToTag

***接口描述***
> 判断tag的内容是否已存在

***参数***

| 参数key   | 参数类型    | 参数解释        |
|---------|---------|-------------|
| tokenId | uint256 | tag的tokenId |

***响应***

| 响应key     | 响应类型    | 响应解释    |
|-----------|---------|---------|
| tokenId   | uint256 | tokenId |
| sortLevel | uint16  | tag排序级别 |
| value     | string  | tag的内容  |

---