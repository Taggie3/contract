import { BigInt, crypto, ByteArray } from '@graphprotocol/graph-ts';
import { NewBrand3SloganCreated } from '../generated/Brand3Factory/Brand3Factory';
import { Brand3SloganDirectory, NFT } from '../generated/schema';
import { Brand3Slogan } from '../generated/templates';
import { Minted } from '../generated/templates/Brand3Slogan/Brand3Slogan';

export function handleNewSlogan(event: NewBrand3SloganCreated): void {
  Brand3Slogan.create(event.params.brand3SloganAddress);
  const bytes = ByteArray.fromUTF8(event.params.brand3SloganAddress.toHexString() + event.params.owner.toHexString());
  const str = crypto.keccak256(bytes).toHexString();
  let entity = Brand3SloganDirectory.load(str);
  if (entity == null) {
    entity = new Brand3SloganDirectory(str);
  }
  entity.sloganAddress = event.params.brand3SloganAddress.toHexString();
  entity.owner = event.params.owner.toHexString();
  entity.save();
  return;
}

export function handleNFTMinted(event: Minted): void {
  const bytes = ByteArray.fromUTF8(event.address.toHexString() + event.params.tokenId.toString());
  const str = crypto.keccak256(bytes).toHexString();
  let entity = NFT.load(str);
  if (entity == null) {
    entity = new NFT(str);
  }
  entity.sloganAddress = event.params.sloganAddress.toHexString();
  entity.tokenId = event.params.tokenId.toString();
  entity.creator = event.params.creator.toHexString();
  entity.splitter = event.params.splitter.toHexString();
  entity.save();
  return;
}
