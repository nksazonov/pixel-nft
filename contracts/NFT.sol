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
	using Strings for uint256;
	using Counters for Counters.Counter;

	// incremental token IDs
	Counters.Counter private _tokenIDs;

	// NFT size
	uint8 constant NFT_SIZE = 16;

	// max image pixel size
	uint8 constant NFT_PIXEL_SIZE = 16;

	// max image size
	uint16 constant NFT_IMAGE_SIZE = NFT_SIZE * NFT_PIXEL_SIZE;

	// tokenID to token data
	mapping(uint256 => uint8[NFT_SIZE][NFT_SIZE]) private _tokenDatas;

	constructor() ERC721('NFT Game', 'NFTG') {}

	function mint() public {
		_tokenIDs.increment();
		uint256 newTokenID = _tokenIDs.current();
		_safeMint(msg.sender, newTokenID);
		_createRandomNFT(newTokenID);
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
			getImage(tokenID),
			'"',
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
	}

	function getImage(uint256 tokenID) public view returns (string memory) {
		bytes memory svg = abi.encodePacked(
			'<svg ',
			'xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" ',
			'viewBox="0 0 ',
			NFT_IMAGE_SIZE,
			' ',
			NFT_IMAGE_SIZE,
			'">',
			_getPixelsSVG(tokenID),
			'</svg>'
		);
		return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
	}

	// INTERNAL FUNCTIONS

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

	// TODO: make sure 0 and 255 values can be achieved
	function _8bitToHex(uint8 color) internal pure returns (string memory) {
		(uint8 r, uint8 g, uint8 b) = _extractRGB(color);
		uint8 red = (r * 255) / 7;
		uint8 green = (g * 255) / 7;
		uint8 blue = (b * 255) / 3;
		return string(abi.encodePacked('#', red, green, blue));
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
		g = (color >> 2) << 3;
		b = color << 5;
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
					x,
					'" y="',
					y,
					'" ',
					'width="',
					NFT_PIXEL_SIZE,
					'" height="',
					NFT_PIXEL_SIZE,
					'" ',
					'fill="',
					_8bitToHex(_tokenDatas[tokenID][row][col]),
					'" ',
					'/>'
				);
			}
			rows = abi.encodePacked(rows, cols);
		}

		return rows;
	}
}
