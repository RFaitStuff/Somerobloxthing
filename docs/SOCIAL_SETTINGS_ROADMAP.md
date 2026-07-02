# Social Chat, Trading, and Settings Roadmap

This document covers systems that are scaffolded now but should be treated carefully before production.

## Current Chat Shape

Implemented files:

- `src/ReplicatedStorage/Shared/Data/Social/ChatChannels.luau`
- `src/ServerScriptService/GameServer/World/SocialChatService.luau`
- `src/StarterPlayer/StarterPlayerScripts/GameClient/UI/HubConsoleClient.luau`

Current channels:

- Server
- Hub
- Squad
- Clan
- Trade
- Room
- Whisper
- System

Messages are sent through custom remotes and filtered on the server with `TextService` before broadcast. The temporary Hub Console consumes the packets, but a final UI can reuse the same `SocialChatUpdate` packet shape.

The server now sends channel availability with the channel snapshot. The temporary UI marks unavailable channels as locked, such as Clan when the player has no clan, Squad when the player is not in a mission session, Hub when the player is not in the hub, and Room when the player is not inside a room.

Supported chat shortcuts:

- `/s message`: server chat.
- `/h message`: hub chat.
- `/sq message`: squad chat.
- `/c message`: clan chat.
- `/t message`: trade chat.
- `/r message`: current room chat.
- `/w player message`: direct same-server whisper.

## Current Clan Shape

Implemented files:

- `src/ReplicatedStorage/Shared/Data/Social/ClanConfig.luau`
- `src/ServerScriptService/GameServer/World/ClanService.luau`

The current clan system is intentionally lightweight for development:

- Clan membership is stored on the player profile.
- Online rosters are in-memory.
- The Hub Console can create a solo clan, join a shared dev clan, leave, and route clan chat.
- `SocialChatService` now sends Clan channel messages to online players with the same `ClanId`.

Before production, clans need persistent clan records, invites, moderation ranks, ownership transfer, member caps across servers, and DataStore conflict handling.

## Chat Production Requirements

Before production, add:

- Per-channel mute/block lists.
- Server-side report hooks.
- Better flood detection across all channels, not just per-channel cooldowns.
- Clan membership validation before `Clan` recipients are expanded.
- Trade channel eligibility checks before posting in `Trade`.
- Better whisper UX, including recent whisper targets, `/reply`, and block-list enforcement.
- Cross-server chat only through a deliberate backend path, such as MessagingService or MemoryStore fanout with moderation constraints.

Do not trust the client to decide recipients, room ownership, clan membership, or trade eligibility.

## Trade System Direction

The current marketplace is only an in-game vendor. Player trading is a separate service.

Implemented files:

- `src/ReplicatedStorage/Shared/Data/Social/TradeConfig.luau`
- `src/ServerScriptService/GameServer/World/TradeService.luau`

Current dev trade flow:

- Players can list stackable materials and room decorations.
- The server removes the listed item from the seller immediately as escrow.
- Online buyers can buy with Coins.
- The seller must currently be online to receive the sale payout.
- Sellers can cancel their own listings to reclaim escrow.

This is a development scaffold, not final trading infrastructure.

Recommended trade flow:

1. Player creates a listing from owned inventory.
2. Server moves the item into escrow.
3. Listing appears in the trade channel or marketplace board.
4. Buyer accepts with server-validated currency/material payment.
5. Server transfers the escrowed item and finalizes the payment.
6. Failed or expired listings return escrow to the seller.

Needed protections:

- Unique item IDs for anything tradable.
- No trading equipped items.
- No client-authored item payloads.
- Per-listing version checks.
- Audit log entries for every escrow, sale, cancel, and failure.

## Settings Direction

Implemented file:

- `src/ServerScriptService/GameServer/Core/SettingsData.luau`
- `src/ReplicatedStorage/Shared/Data/Settings/SettingsSchema.luau`
- `src/StarterPlayer/StarterPlayerScripts/GameClient/Settings/SettingsClient.luau`

Current settings save/load uses a DataStore-backed remote function and a shared schema. The server sanitizes settings and rebind payloads before caching or saving them.

Settings categories to support:

- Input sensitivity and inversion.
- Keybinds/gamepad binds.
- Camera shoulder, aim, and FOV preferences.
- Chat visibility and channel filters.
- Accessibility options.
- Graphics/performance toggles that are safe for the client to own.
- UI scale and HUD layout preferences.

Rules:

- Validate every setting key and value range on the server before saving. `SettingsSchema` now does this for the current fields.
- Version settings payloads so renamed keys can migrate cleanly.
- Keep combat-affecting values out of user settings unless the server treats them as cosmetic only.

The temporary Hub Console has a Settings tab for sensitivity, camera FOV, UI scale, chat visibility, damage numbers, crouch behavior, and reduce-motion style preferences.

## Room Chat Direction

Room chat currently uses `RoomOwnerUserId` from server player state. When visiting other players' rooms exists, the enter-room flow should set:

- Visitor location: `Room`
- Visitor room owner: target owner's user id
- Visitor permission level: owner, friend, clan, invite, or public

Room chat recipients should be players whose server state points at the same room owner and who still satisfy room privacy rules.
