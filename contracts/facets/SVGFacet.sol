// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {Base64} from "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract SVGFacet {
    using Strings for uint256;

    AppStorage internal s;

    // All traits are derived deterministically from tokenId.
    // No randomness, no oracle, no storage — just integer math.
    // The same token always produces the same image.

    // 6 background palettes — each is a pair: (bg fill, accent color)
    function _palette(uint256 tokenId) internal pure returns (string memory bg, string memory accent) {
        uint256 idx = tokenId % 6;
        if (idx == 0) return ("#050510", "#00ffcc"); // deep navy / cyan
        if (idx == 1) return ("#0d0005", "#ff00aa"); // deep crimson / magenta
        if (idx == 2) return ("#050d00", "#aaff00"); // deep forest / acid green
        if (idx == 3) return ("#0a0500", "#ff6600"); // deep ember / orange
        if (idx == 4) return ("#00050d", "#00aaff"); // deep ocean / sky blue
        return ("#08000d", "#cc00ff"); // deep void / purple
    }

    // 4 eye colors
    function _eyeColor(uint256 tokenId) internal pure returns (string memory) {
        uint256 idx = tokenId % 4;
        if (idx == 0) return "#00ffcc";
        if (idx == 1) return "#ff00aa";
        if (idx == 2) return "#ffcc00";
        return "#00aaff";
    }

    // 3 eye shapes — returns (rx, ry) for the eye rect's border radius
    // We encode as two separate uints to keep concatenation simple
    function _eyeShape(uint256 tokenId) internal pure returns (uint256 rx, uint256 ry) {
        uint256 idx = (tokenId / 4) % 3;
        if (idx == 0) return (8, 8); // round pill
        if (idx == 1) return (2, 2); // angular slit
        return (4, 1); // wide flat
    }

    // 3–6 mouth segments
    function _mouthCount(uint256 tokenId) internal pure returns (uint256) {
        return 3 + (tokenId % 4);
    }

    // 4 circuit trace layouts — encoded as a small index
    function _circuitLayout(uint256 tokenId) internal pure returns (uint256) {
        return (tokenId / 2) % 4;
    }

    // Rarity: derived from a pseudo-hash of tokenId.
    // Legendary ~5%, Rare ~20%, Common rest.
    function _rarity(uint256 tokenId) internal pure returns (string memory) {
        uint256 h = uint256(keccak256(abi.encodePacked(tokenId))) % 100;
        if (h < 5) return "Legendary";
        if (h < 25) return "Rare";
        return "Common";
    }

    // ── SVG builders ─────────────────────────────────────────────────────────

    function _buildEyes(uint256 tokenId, string memory eyeColor) internal pure returns (string memory) {
        (uint256 rx, uint256 ry) = _eyeShape(tokenId);
        string memory rxStr = rx.toString();
        string memory ryStr = ry.toString();

        // Left eye at x=275, right eye at x=355, both at y=265, w=50 h=16
        // Pupil is a small dark rect centered inside each eye
        return string.concat(
            // Left eye
            "<rect x='275' y='265' width='50' height='16' rx='",
            rxStr,
            "' ry='",
            ryStr,
            "' fill='",
            eyeColor,
            "'/>",
            // Left pupil
            "<rect x='293' y='269' width='14' height='8' rx='3' fill='#050510'/>",
            // Right eye
            "<rect x='355' y='265' width='50' height='16' rx='",
            rxStr,
            "' ry='",
            ryStr,
            "' fill='",
            eyeColor,
            "'/>",
            // Right pupil
            "<rect x='373' y='269' width='14' height='8' rx='3' fill='#050510'/>"
        );
    }

    function _buildMouth(uint256 tokenId, string memory accent) internal pure returns (string memory) {
        uint256 count = _mouthCount(tokenId);
        // Segments start at x=285, each is 14px wide with 6px gap = 20px stride
        // This centres the mouth group around x=340
        uint256 totalWidth = count * 14 + (count - 1) * 6;
        uint256 startX = 340 - totalWidth / 2;

        string memory segments = "";
        for (uint256 i = 0; i < count; i++) {
            uint256 xPos = startX + i * 20;
            segments = string.concat(
                segments, "<rect x='", xPos.toString(), "' y='350' width='14' height='8' rx='1' fill='", accent, "'/>"
            );
        }
        return segments;
    }

    // 4 circuit trace layouts — thin decorative lines in the corner regions
    function _buildCircuits(uint256 tokenId, string memory accent) internal pure returns (string memory) {
        uint256 layout = _circuitLayout(tokenId);
        string memory col = accent;

        if (layout == 0) {
            return string.concat(
                "<g fill='none' stroke='",
                col,
                "' stroke-width='1' opacity='0.4'>",
                "<polyline points='60,520 60,560 100,560'/>",
                "<circle cx='60' cy='520' r='3' fill='",
                col,
                "'/>",
                "<polyline points='620,140 580,140 580,100'/>",
                "<circle cx='620' cy='140' r='3' fill='",
                col,
                "'/>",
                "</g>"
            );
        }
        if (layout == 1) {
            return string.concat(
                "<g fill='none' stroke='",
                col,
                "' stroke-width='1' opacity='0.4'>",
                "<polyline points='60,480 100,480 100,520 140,520'/>",
                "<circle cx='100' cy='480' r='3' fill='",
                col,
                "'/>",
                "<polyline points='620,180 580,180 580,220 540,220'/>",
                "<circle cx='580' cy='180' r='3' fill='",
                col,
                "'/>",
                "</g>"
            );
        }
        if (layout == 2) {
            return string.concat(
                "<g fill='none' stroke='",
                col,
                "' stroke-width='1' opacity='0.4'>",
                "<polyline points='60,500 80,500 80,540 120,540 120,560'/>",
                "<circle cx='80' cy='500' r='3' fill='",
                col,
                "'/>",
                "<polyline points='620,160 600,160 600,120 560,120 560,100'/>",
                "<circle cx='600' cy='160' r='3' fill='",
                col,
                "'/>",
                "</g>"
            );
        }
        // layout == 3
        return string.concat(
            "<g fill='none' stroke='",
            col,
            "' stroke-width='1' opacity='0.4'>",
            "<polyline points='60,540 70,540 70,510 110,510'/>",
            "<polyline points='60,560 90,560 90,580'/>",
            "<circle cx='70' cy='540' r='3' fill='",
            col,
            "'/>",
            "<polyline points='620,120 610,120 610,150 570,150'/>",
            "<circle cx='610' cy='120' r='3' fill='",
            col,
            "'/>",
            "</g>"
        );
    }

    function _buildSVG(uint256 tokenId, string memory nftName) internal pure returns (string memory) {
        (string memory bg, string memory accent) = _palette(tokenId);
        string memory eyeColor = _eyeColor(tokenId);
        // Face bg is slightly lighter than card bg — derived by convention
        string memory faceBg = "#0a0a20";

        string memory part1 = _buildSVGPart1(bg, accent);
        string memory circuits = _buildCircuits(tokenId, accent);
        string memory part2 = _buildSVGPart2(accent);
        string memory part3 = _buildSVGPart3(faceBg, accent, eyeColor, tokenId);
        string memory part4 = _buildSVGPart4(accent, tokenId, nftName);

        return string.concat(part1, circuits, part2, part3, part4);
    }

    function _buildSVGPart1(string memory bg, string memory accent) internal pure returns (string memory) {
        return string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 680 680'>",
            // Card background
            "<rect x='40' y='40' width='600' height='600' rx='8' fill='",
            bg,
            "'/>",
            // Grid (accent colored, very faint)
            "<g stroke='",
            accent,
            "' stroke-width='0.4' opacity='0.12'>",
            "<line x1='40' y1='160' x2='640' y2='160'/>",
            "<line x1='40' y1='280' x2='640' y2='280'/>",
            "<line x1='40' y1='400' x2='640' y2='400'/>",
            "<line x1='40' y1='520' x2='640' y2='520'/>",
            "<line x1='160' y1='40' x2='160' y2='640'/>",
            "<line x1='280' y1='40' x2='280' y2='640'/>",
            "<line x1='400' y1='40' x2='400' y2='640'/>",
            "<line x1='520' y1='40' x2='520' y2='640'/>",
            "</g>",
            // Corner brackets
            "<g fill='none' stroke='",
            accent,
            "' stroke-width='2'>",
            "<polyline points='40,80 40,40 80,40'/>",
            "<polyline points='600,40 640,40 640,80'/>",
            "<polyline points='640,600 640,640 600,640'/>",
            "<polyline points='80,640 40,640 40,600'/>",
            "</g>"
        );
    }

    function _buildSVGPart2(string memory accent) internal pure returns (string memory) {
        return string.concat(
            // Outer border
            "<rect x='40' y='40' width='600' height='600' rx='8' fill='none' stroke='",
            accent,
            "' stroke-width='1' opacity='0.5'/>"
        );
    }

    function _buildSVGPart3(string memory faceBg, string memory accent, string memory eyeColor, uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            // Face
            "<ellipse cx='340' cy='300' rx='110' ry='130' fill='",
            faceBg,
            "' stroke='",
            accent,
            "' stroke-width='1.5'/>",
            "<rect x='230' y='390' width='220' height='40' fill='",
            faceBg,
            "'/>",
            "<line x1='230' y1='390' x2='460' y2='390' stroke='",
            accent,
            "' stroke-width='1.5'/>",
            // Eyes (shape and color vary per token)
            _buildEyes(tokenId, eyeColor),
            // Nose bridge
            "<line x1='340' y1='290' x2='340' y2='325' stroke='",
            accent,
            "' stroke-width='1' opacity='0.4'/>",
            "<line x1='328' y1='325' x2='352' y2='325' stroke='",
            accent,
            "' stroke-width='1' opacity='0.4'/>",
            // Mouth (count varies per token)
            _buildMouth(tokenId, accent)
        );
    }

    function _buildSVGPart4(string memory accent, uint256 tokenId, string memory nftName)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            // Token name badge
            "<rect x='270' y='56' width='140' height='26' rx='4' fill='none' stroke='",
            accent,
            "' stroke-width='1'/>",
            "<text x='340' y='74' font-family='monospace' font-size='12' fill='",
            accent,
            "' text-anchor='middle'>",
            nftName,
            "</text>",
            // HUD bottom bar
            "<rect x='40' y='610' width='600' height='30' fill='#000000'/>",
            "<rect x='40' y='610' width='600' height='1' fill='",
            accent,
            "' opacity='0.4'/>",
            "<text x='60' y='630' font-family='monospace' font-size='10' fill='",
            accent,
            "'>CHAIN: EVM  RARITY: ",
            _rarity(tokenId),
            "  ID: #",
            tokenId.toString(),
            "</text>",
            "</svg>"
        );
    }

    // ── Public interface ──────────────────────────────────────────────────────

    function setTokenSVG(uint256 tokenId, string calldata svg) external {
        LibAppStorage.enforceOwner();
        s.tokenSVGOverride[tokenId] = svg;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(s.owners[tokenId] != address(0), "Not minted");

        string memory idStr = tokenId.toString();
        string memory nftName = string.concat("OnChain NFT #", idStr);

        string memory svg =
            bytes(s.tokenSVGOverride[tokenId]).length > 0 ? s.tokenSVGOverride[tokenId] : _buildSVG(tokenId, nftName);

        string memory image = string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svg)));

        string memory attributes = _buildAttributes(tokenId);

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"',
                    nftName,
                    '","description":"On-chain cyberpunk NFT","image":"',
                    image,
                    '","attributes":',
                    attributes,
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    function _buildAttributes(uint256 tokenId) internal view returns (string memory) {
        (, string memory accent) = _palette(tokenId);
        string memory staked = s.stakes[tokenId].staker != address(0) ? "true" : "false";
        string memory borrowed = s.borrows[tokenId].borrower != address(0) ? "true" : "false";
        string memory listed = s.listings[tokenId].active ? "true" : "false";

        return string.concat(
            "[",
            '{"trait_type":"Palette","value":"',
            accent,
            '"},',
            '{"trait_type":"Eye Color","value":"',
            _eyeColor(tokenId),
            '"},',
            '{"trait_type":"Mouth Segments","value":',
            _mouthCount(tokenId).toString(),
            "},",
            '{"trait_type":"Rarity","value":"',
            _rarity(tokenId),
            '"},',
            '{"trait_type":"Staked","value":',
            staked,
            "},",
            '{"trait_type":"Borrowed","value":',
            borrowed,
            "},",
            '{"trait_type":"Listed","value":',
            listed,
            "}",
            "]"
        );
    }
}
