# Brand3Dao

## 整体介绍
此项目将用户所拥有的nft数据都保存在区块链上，用户数据和关联关系数据采用关系型数据库的方式保存。其中需要用到的链上数据都使用event进行抛出，并建立了the graph以便进行查询。  
>the graph address：待补充

[the graph介绍](https://thegraph.com/en/)

## 链上部分架构介绍
```puml
@startuml
'https://plantuml.com/class-diagram

class ERC721{}
class PaymentSplitter{}
abstract class ERC721Enumerable{}
abstract class Pausable{}
abstract class Ownable{}
abstract class ERC721Burnable{}
abstract class ERC721Royalty{}
class Brand3Factory{
    + Brand3Tag brand3Tag
    + Brand3Slogan[] SloganArray

    void constructor(address brand3TagAddress)
    + void createNewSlogan(uint256 _nonce,string _signature,string _baseURI,string _name,string _symbol,string _logoUrl,uint256[] tagIds)
    + Brand3Slogan[] getBrand3Slogan()
}
note left of Brand3Factory::"createNewSlogan"
    创建新的slogan合约
end note
note left of Brand3Factory::"getBrand3Slogan"
    获取当前所有的slogan合约
end note

class Brand3Slogan extends ERC721,ERC721Enumerable,Pausable,Ownable,ERC721Burnable,ERC721Royalty{
    + string _baseTokenURI
    + string logoUrl
    + uint256[] tagIds

    void constructor(string baseURI,string _name,string _symbol,string _logoUrl,uint256[] _tagIds)
    + void updateLogo(string _logoUrl)
    + void mint(address creator, address splitter)
    + uint256[] getTagIds()

}

note left of Brand3Slogan::"mint"
    在slogan中mint一个新的nft
    creator: nft所有者的地址
    splitter: 一个分账合约的地址，版税的所得金额将会打到此合约，再通过这个合约进行分账
end note
note left of Brand3Slogan::"getTagIds"
    获取当前slogan对应的tag的nft的tokenId
end note

class Brand3Tag extends ERC721,ERC721Enumerable,Pausable,Ownable,ERC721Burnable{
    +   mapping(uint256 => Tag) tokenIdToTag
    +   mapping(string => Tag) tagValueToTag
    +   mapping(string => bool) tagValueToExist
    +   mapping(address => bool) addressToMint

    +   void constructor()
    +   void mint(string tagValue, uint16 sortLevel)
    +   string makeSlogan(uint256[] tokenIds, string[] linkStrs)
    +   void  addMintAddress(address addr)
    +   void  delMintAddress(address addr)
}
note right of Brand3Tag::"tokenIdToTag"
    tokenId对应的tag
end note
note right of Brand3Tag::"tagValueToTag"
    tagValue对应的tag
end note
note right of Brand3Tag::"tagValueToExist"
    tagValue是否已存在
end note
note right of Brand3Tag::"addressToMint"
    记录所有已被授权可以mint的地址
end note
note right of Brand3Tag::"mint"
    在Tag中mint一个新的nft
    tagValue: tag的内容
    sortLevel: tag的排序级别
end note
note right of Brand3Tag::"makeSlogan"
    将tag和连接字符串拼接成为一个新的slogan字符串
end note


class Tag {
    uint256 tokenId
    uint16 sortLevel
    string value
}

class RoyaltySplitter extends PaymentSplitter{}

Brand3Tag --> Brand3Factory::brand3Tag
Brand3Slogan --> Brand3Factory::SloganArray
RoyaltySplitter --> Brand3Slogan::mint
Tag --> Brand3Tag::tokenIdToTag
Tag --> Brand3Tag::tagValueToTag
Brand3Factory::createNewSlogan -[dashed]-> Brand3Slogan

@enduml
```
合约的整体架构如图所示  
其中最核心的3个合约分别为
* Brand3Tag
  > 一个NFT合约，其中每一个Tag都视为一个NFT，Tag最终会通过Slogan与User建立联系，以便标注User的偏好类型。
* Brand3Slogan
  > 一个普通的NFT合约，每当新建一个Slogan的时候都会部署一个新的合约，所以此合约会部署多个实例。  
  > 在合约中可以mint不同的内容作为NFT的内容。
* Brand3Factory
  > Slogan合约的工厂合约，通过此合约部署新增的Slogan合约。在此合约中会记录所有已部署的slogan合约。

## 如何新增Tag
```puml
@startuml
'https://plantuml.com/sequence-diagram

autonumber

actor applicant as applicant
actor admin as admin
participant backend as backend
entity "tag smart contract" as contract
participant "the graph" as graph

applicant --> backend: 申请一个新的tag,并将请求保存在数据库中
admin --> backend: 发现有一个新的tag申请
admin --> backend: 同意mint一个新的tag
backend --> contract: 在tag合约中mint一个新的nft
contract --> graph: 监听mint的event并保存数据

@enduml
```
## 如何新增Slogan
```puml
@startuml
'https://plantuml.com/sequence-diagram

autonumber

actor applicant as applicant
actor admin as admin
participant backend as backend
entity "tag smart contract" as tagContract
entity "factory smart contract" as factoryContract
entity "slogan smart contract" as sloganContract
participant "the graph" as graph

applicant --> backend: 申请一个新的slogan,并将请求保存在数据库中
admin --> backend: 发现有一个新的slogan申请
admin --> backend: 同意生成一个新的slogan
backend --> factoryContract: 调用createNewSlogan()尝试生成新的slogan合约
factoryContract --> tagContract: 检查tag数据是否有误
factoryContract --> sloganContract: 部署一个新的slogan合约
factoryContract --> graph: 监听新slogan合约建立的event并记录


@enduml
```
## 各合约的接口文档