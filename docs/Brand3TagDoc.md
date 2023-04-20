> goerli地址：0xaCDc3aF383ee41a1Fd900a1BF47AEB7dE1269cAF

# bytecode
[Brand3TagBytecode.json](Brand3TagBytecode.json)

# abi
[Brand3TagAbi.json](Brand3TagAbi.json)

---

# addMintAddress

***接口描述***
> 增加可以mint的address，授权address可以mint后，对应的address即可调用此合约的mint方法

***参数***

| 参数key | 参数类型    | 参数解释        |
|-------|---------|-------------|
| addr  | address | 要增加的address |

***响应***
> 无
---

# delMintAddress

***接口描述***
> 删除可以mint的address，删除address后，对应的address无法调用此合约的mint方法

***参数***

| 参数key | 参数类型    | 参数解释        |
|-------|---------|-------------|
| addr  | address | 要增加的address |

***响应***
> 无
---

# mint

***接口描述***
> 增加一个tag资源

***参数***

| 参数key     | 参数类型   | 参数解释     |
|-----------|--------|----------|
| tagValue  | string | tag的内容   |
| sortLevel | uint16 | tag的排序等级 |

***响应***
> 无
---

# makeSlogan

***接口描述***
> 根据tag的id和连接词组装出一个完整的slogan，如果希望以tag内容开头，则linkStrs第一个传空字符串即可

## 举例：

现有如下tag

| tokenId | sortLevel | value |
|---------|-----------|-------|
| 1       | 1         | tag1  |
| 2       | 1         | tag2  |
| 3       | 2         | tag3  |
| 4       | 3         | tag4  |

传参：

```json
{
  "tokenIds": [
    1,
    2,
    3,
    4
  ],
  "linkStrs": [
    "link1",
    "link2",
    "link3",
    "link4"
  ]
}
```

返回：
> link1 tag1 tag2 link2 tag3 link3 tag4 link4

***参数***

| 参数key    | 参数类型      | 参数解释      |
|----------|-----------|-----------|
| tokenIds | uint256[] | tokenId集合 |
| linkStrs | string[]  | 连接词       |

***响应***

| 响应类型   | 响应解释         |
|--------|--------------|
| string | 生成的slogan字符串 |

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