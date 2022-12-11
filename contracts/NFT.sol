// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

// NOTE: max number of colors is 256.
// NOTE: max resolution of NFT picture is 2^16 x 2^16.

contract NFT is ERC721 {
	using Strings for uint8;
	using Strings for uint16;
	using Strings for uint256;
	using Counters for Counters.Counter;

	constructor() ERC721('NFT Game', 'NFTG') {}

	// =================
	// NFT
	// =================

	// incremental token IDs
	Counters.Counter public lastTokenID;

	// NFT size
	uint8 constant PIXELS_AMOUNT = 8;

	// max image pixel size
	uint8 constant PIXEL_SIZE = 12;

	// max image size
	// when dynamically calculating image size, OpenZeppelin's `toString` reverts
	// uint16 constant IMAGE_SIZE = PIXELS_AMOUNT * PIXEL_SIZE;
	uint16 constant IMAGE_SIZE = 96;

	// tokenID to token data
	mapping(uint256 => uint8[PIXELS_AMOUNT][PIXELS_AMOUNT]) internal _pixelsOf;

	// user to array of token IDs
	mapping(address => uint256[]) internal _tokensOf;

	// start changeable pixels
	uint256 constant START_CHANGEABLE_PIXELS = PIXELS_AMOUNT;

	struct ChangePixelPayload {
		uint8 row;
		uint8 col;
		uint8 newColor;
	}

	// account to amount of changeable pixels
	mapping(address => uint256) public _changeablePixelsOf;

	function tokensOf(address user) external view returns (uint256[] memory) {
		return _tokensOf[user];
	}

	function mint() public {
		address minter = msg.sender;

		uint256 newTokenID = lastTokenID.current();
		_safeMint(minter, newTokenID);
		_createRandomNFT(newTokenID);
		_tokensOf[minter].push(newTokenID);

		_grantChangeablePixels(minter, START_CHANGEABLE_PIXELS);

		lastTokenID.increment();
	}

	function tokenPixelSize() external pure returns (uint8) {
		return PIXELS_AMOUNT;
	}

	function tokenURI(uint256 tokenID) public view override returns (string memory) {
		bytes memory dataURI = abi.encodePacked(
			'{',
			'"name": "Game NFT #',
			tokenID.toString(),
			'",',
			'"description": "Pixel NFT",',
			'"image": "',
			tokenSVG(tokenID),
			'"',
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
	}

	function tokenSVG(uint256 tokenID) public view returns (string memory) {
		bytes memory svg = abi.encodePacked(
			'<svg ',
			'xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" ',
			'viewBox="0 0 ',
			IMAGE_SIZE.toString(),
			' ',
			IMAGE_SIZE.toString(),
			'">',
			_pixelSVG(tokenID),
			'</svg>'
		);
		return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
	}

	function tokenData(
		uint256 tokenId
	) public view returns (uint8[PIXELS_AMOUNT][PIXELS_AMOUNT] memory) {
		return _pixelsOf[tokenId];
	}

	// =================
	// INTERNAL NFT
	// =================

	// TODO: use better randomizing source
	function _createRandomNFT(uint256 tokenID) internal {
		uint256 presentPixels = uint256(keccak256(abi.encode(block.timestamp)));
		uint256 pixelColorSeed = uint256(keccak256(abi.encode(block.number)));

		for (uint8 row = 0; row < PIXELS_AMOUNT; row++) {
			for (uint8 col = 0; col < PIXELS_AMOUNT; col++) {
				if (_bitPresent(presentPixels, row * PIXELS_AMOUNT + col)) {
					uint8 color = uint8((pixelColorSeed >> ((row + 1) * (col + 1))) % 256);
					_pixelsOf[tokenID][col][row] = color;
				}
			}
		}
	}

	function _bitPresent(uint256 num, uint8 bitIdx) internal pure returns (bool) {
		return ((num >> bitIdx) % 2 == 1);
	}

	function _pixelSVG(uint256 tokenID) internal view returns (bytes memory) {
		bytes memory rows;

		for (uint8 row = 0; row < PIXELS_AMOUNT; row++) {
			bytes memory cols;
			for (uint8 col = 0; col < PIXELS_AMOUNT; col++) {
				uint16 x = row * PIXEL_SIZE;
				uint16 y = col * PIXEL_SIZE;

				cols = abi.encodePacked(
					cols,
					'<rect ',
					'x="',
					x.toString(),
					'" y="',
					y.toString(),
					'" ',
					'width="',
					PIXEL_SIZE.toString(),
					'" height="',
					PIXEL_SIZE.toString(),
					'" ',
					'fill="',
					_8bitToRGB(_pixelsOf[tokenID][col][row]),
					'" ',
					'/>'
				);
			}
			rows = abi.encodePacked(rows, cols);
		}

		return rows;
	}

	function _requireCallerOwner(uint256 tokenId) internal view {
		require(msg.sender == ownerOf(tokenId), 'Caller is not token owner');
	}

	// =================
	// CHANGEABLE PIXELS
	// =================

	function getChangeablePixelsOf(address user) external view returns (uint256) {
		return _changeablePixelsOf[user];
	}

	function changePixel(uint256 tokenId, ChangePixelPayload memory cpp) public {
		_requireCallerOwner(tokenId);
		_requireHasChangeablePixels(msg.sender, 1);

		_changePixel(tokenId, cpp);
	}

	function changePixelTxData(
		uint256 tokenId,
		ChangePixelPayload memory cpp
	) external pure returns (bytes memory) {
		return abi.encode(tokenId, cpp);
	}

	function changePixels(uint256 tokenId, ChangePixelPayload[] memory cpps) external {
		_requireCallerOwner(tokenId);
		_requireHasChangeablePixels(msg.sender, cpps.length);

		for (uint256 i = 0; i < cpps.length; i++) {
			_changePixel(tokenId, cpps[i]);
		}
	}

	function changePixelsTxData(
		uint256 tokenId,
		ChangePixelPayload[] memory cpps
	) external pure returns (bytes memory) {
		return abi.encode(tokenId, cpps);
	}

	// =================
	// INTERNAL CHANGEABLE PIXELS
	// =================

	function _grantChangeablePixels(address account, uint256 amount) internal {
		_changeablePixelsOf[account] += amount;
	}

	function _requireHasChangeablePixels(address account, uint256 amount) internal view {
		require(_changeablePixelsOf[account] >= amount, 'Not enough changeable pixels');
	}

	function _changePixel(uint256 tokenId, ChangePixelPayload memory cpp) internal {
		_pixelsOf[tokenId][cpp.col][cpp.row] = cpp.newColor;
		// todo: decrement changeable pixels
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

	function _extractRGB(uint8 color) internal pure returns (uint8 r, uint8 g, uint8 b) {
		r = color >> 5;
		g = (color >> 2) & 7;
		b = color & 3;
	}
}
