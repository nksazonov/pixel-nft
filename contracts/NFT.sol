// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

// NOTE: max number of colors is 256.
// NOTE: max resolution of NFT picture is 2^16 x 2^16.

// TODO: refactor
contract NFT is ERC721 {
	using Strings for uint8;
	using Strings for uint16;
	using Strings for uint256;
	using Counters for Counters.Counter;

	// incremental token IDs
	Counters.Counter private _tokenIDs;

	// NFT size
	uint8 constant NFT_SIZE = 15;

	// max image pixel size
	uint8 constant NFT_PIXEL_SIZE = 12;

	// max image size
	// TODO: report bug
	// uint16 constant NFT_IMAGE_SIZE = NFT_SIZE * NFT_PIXEL_SIZE;
	uint16 constant NFT_IMAGE_SIZE = 180;

	// tokenID to token data
	mapping(uint256 => uint8[NFT_SIZE][NFT_SIZE]) private _tokenDatas;

	constructor() ERC721('NFT Game', 'NFTG') {}

	function mint() public {
		uint256 newTokenID = _tokenIDs.current();
		_safeMint(msg.sender, newTokenID);
		_createRandomNFT(newTokenID);

		_tokenIDs.increment();
	}

	// TODO: change names
	function getTokenURI(uint256 tokenID) public view returns (string memory) {
		bytes memory dataURI = abi.encodePacked(
			'{',
			'"name": "Game NFT #',
			tokenID.toString(),
			'",',
			'"description": "Pixel NFT",',
			'"image": "',
			getTokenSVG(tokenID),
			'"',
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
	}

	function getTokenSVG(uint256 tokenID) public view returns (string memory) {
		bytes memory svg = abi.encodePacked(
			'<svg ',
			'xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" ',
			'viewBox="0 0 ',
			NFT_IMAGE_SIZE.toString(),
			' ',
			NFT_IMAGE_SIZE.toString(),
			'">',
			_getPixelsSVG(tokenID),
			'</svg>'
		);
		return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
	}

	function getTokenData(uint256 tokenID) public view returns (uint8[NFT_SIZE][NFT_SIZE] memory) {
		return _tokenDatas[tokenID];
	}

	// =================
	// INTERNAL
	// =================

	// TODO: use better randomizing source
	function _createRandomNFT(uint256 tokenID) internal {
		uint256 presentPixels = uint256(keccak256(abi.encode(block.timestamp)));
		uint256 pixelColorSeed = uint256(keccak256(abi.encode(block.number)));

		for (uint8 row = 0; row < NFT_SIZE; row++) {
			for (uint8 col = 0; col < NFT_SIZE; col++) {
				if (_bitPresent(presentPixels, row * NFT_SIZE + col)) {
					uint8 color = uint8((pixelColorSeed >> ((row + 1) * (col + 1))) % 256);
					_tokenDatas[tokenID][row][col] = color;
				}
			}
		}
	}

	function _bitPresent(uint256 num, uint8 bitIdx) internal pure returns (bool) {
		return ((num >> bitIdx) % 2 == 1);
	}

	function _getPixelsSVG(uint256 tokenID) internal view returns (bytes memory) {
		bytes memory rows;

		for (uint8 row = 0; row < NFT_SIZE; row++) {
			bytes memory cols;
			for (uint8 col = 0; col < NFT_SIZE; col++) {
				uint16 x = row * NFT_PIXEL_SIZE;
				uint16 y = col * NFT_PIXEL_SIZE;

				cols = abi.encodePacked(
					cols,
					'<rect ',
					'x="',
					x.toString(),
					'" y="',
					y.toString(),
					'" ',
					'width="',
					NFT_PIXEL_SIZE.toString(),
					'" height="',
					NFT_PIXEL_SIZE.toString(),
					'" ',
					'fill="',
					_8bitToRGB(_tokenDatas[tokenID][row][col]),
					'" ',
					'/>'
				);
			}
			rows = abi.encodePacked(rows, cols);
		}

		return rows;
	}

	// =================
	// COLORS
	// =================

	function _8bitToRGB(uint8 color) internal pure returns (string memory) {
		(uint8 r, uint8 g, uint8 b) = _extractRGB(color);
		uint8 red = uint8((uint16(r) * 255) / 7);
		uint8 green = uint8((uint16(g) * 255) / 7);
		uint8 blue = uint8((uint16(b) * 255) / 3);

		return
			string(
				abi.encodePacked(
					'rgb(',
					red.toString(),
					',',
					green.toString(),
					',',
					blue.toString(),
					')'
				)
			);
	}

	function _extractRGB(uint8 color)
		internal
		pure
		returns (
			uint8 r,
			uint8 g,
			uint8 b
		)
	{
		r = color >> 5;
		g = (color >> 2) & 7;
		b = color & 3;
	}
}
