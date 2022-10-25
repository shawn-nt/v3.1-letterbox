//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./RMRK/utils/RMRKMintingUtils.sol";
import "./RMRK/utils/RMRKCollectionMetadata.sol";
import "./RMRK/multiresource/RMRKMultiResource.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//LOOK check implementation example - includes MintingUtils and CollectionMetadata but left out here as we don't want maxSupply
contract LetterboxV3 is RMRKMultiResource {
    //
    //Types States and Other Variables Stuff
    //
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdAuto;
    Counters.Counter private _resourceIdAuto;

    uint256 private _mintFee;
    bool private paused;
    address private _admin;

    //this is a list of letterbox IDs that exist.
    uint256[] letterboxlist;

    //which Ids exist as letterboxes held by users
    struct OwnedLetterboxesInfo {
        uint256[] letterboxIds;
    }
    //mapping connecting an address to Letterbox
    mapping(address => OwnedLetterboxesInfo) internal letterboxesToAddresses;

    // this is to a uint256 and not array because stamp to address should be 1:1 relationship
    mapping(address => uint256) internal stampsToAddresses;

    //
    //QR Code specific needs
    //

    //in order to make sure you can get token ID from a URL

    mapping(string => uint256) internal letterboxUrlToTokenId;

    //this is so that you can have a list of just all the hashs for letterboxes
    string[] letterboxURLlist;
    //
    // Events --------
    //

    event ContractPaused(bool paused);
    event ResourceAdded(uint256 indexed tokenId, uint64 indexed resourceId);
    event StampCreated(uint256 indexed tokenId);
    event LetterboxCreated(uint256 indexed tokenId);
    event LetterboxStamped();
    event LetterboxCollected();

    //
    //Constructor ----
    //

    constructor(string memory name, string memory symbol)
        RMRKMultiResource(name, symbol)
    {
        paused = false;
        _admin = msg.sender;
        _mintFee = 0;
        _resourceIdAuto.increment(); //resource cannot be at index 0 per standard
        _tokenIdAuto.increment();
    }

    //
    //  --- Modifiers ---
    //

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not authorized for this action");
        _;
    }

    modifier isStampEligible(address to_) {
        //need to cehck to see if address already owns one.
        require(stampHeldBy(to_) == 0, "Only one stamp per address");
        _;
    }

    modifier isNotPaused() {
        require(paused == false, "no minting is permitted at this time");
        _;
    }

    //
    //    Public Functions -----  Key action functions
    //

    //this function is for the initial mint of the stamp for
    //those in the "finder" role.
    function mintStamp(address to_, string memory uri_)
        public
        payable
        isStampEligible(to_)
        isNotPaused
    {
        require(
            msg.value >= _mintFee,
            "Insufficient funds sent with transaction"
        );
        uint256 newTokenId;
        newTokenId = mintInitial(to_, uri_);
        mapStampAddr(to_, newTokenId);
        emit StampCreated(newTokenId);
    }

    //this function mints new letterboxes, much like new finder stamps
    //however, with no test for a charge

    //NOTE: need to change the to_ address to be msg.sender or people could spam each other programmatically - want the owner to be the actual person who mints.
    function mintLetterbox(
        address to_,
        string memory url_,
        string memory uri_
    ) public isNotPaused {
        uint256 newTokenId = mintInitial(to_, uri_);

        mapLetterboxAddr(to_, newTokenId);
        letterboxlist.push(newTokenId);
        letterboxUrlToTokenId[url_] = newTokenId;
        letterboxURLlist.push(url_);
        emit LetterboxCreated(newTokenId);
    }

    //NOTE: Change stampUser parameter to be actually the msg.sender instead of a param so that people cannot programmatically stamp on behalf of others, to reduce spam.
    //this is used as a param at present for cross-chain experimentation
    function stampToLetterbox(
        address stampUser,
        uint256 letterboxTokenId,
        bool accepted
    )
        public
        isNotPaused //should have hasStamp modifier?
    {
        string memory stampMetadata = stampMetadataURI(stampUser);
        createAndAddResource(letterboxTokenId, stampMetadata, accepted);
        emit LetterboxStamped();
    }

    function letterboxToStamp(address stampUser, uint256 letterboxTokenId)
        public
        isNotPaused
    //should this have hasStamp as modifier?
    {
        //should add custom data for letterboxer to choose autoaccept
        string memory letterboxMetadata;
        letterboxMetadata = letterboxMetadataURI(letterboxTokenId);
        uint256 stampReceiving = stampHeldBy(stampUser);
        createAndAddResource(stampReceiving, letterboxMetadata, true);
        emit LetterboxCollected();
    }

    //
    // Public Functions -- Main view functions
    //
    function letterboxesHeldBy(address owner)
        public
        view
        returns (uint256[] memory)
    {
        //ATTENTION - review and remove or update
        // require(
        //     letterboxesToAddresses[owner].letterboxIds[0] > 0,
        //     "user has not minted letterbox"
        // );

        return letterboxesToAddresses[owner].letterboxIds;
    }

    function getLetterboxFromURL(string memory url)
        public
        view
        returns (string memory, uint256)
    {
        uint256 tokenId = letterboxUrlToTokenId[url];
        return (letterboxMetadataURI(tokenId), tokenId);
    }

    function stampHeldBy(address owner) public view returns (uint256) {
        return stampsToAddresses[owner];
    }

    function letterboxList() public view returns (uint256[] memory) {
        return letterboxlist;
    }

    function letterboxUrlList() public view returns (string[] memory) {
        return letterboxURLlist;
    }

    //should this be a modifier instead of a function??
    function hasStamp(address owner) public view returns (bool) {
        if (stampHeldBy(owner) == 0) {
            return false;
        } else {
            return true;
        }
    }

    function stampMetadataURI(address owner)
        public
        view
        returns (string memory)
    {
        if (hasStamp(owner) == true) {
            uint64[] memory stampResources = getActiveResources(
                stampHeldBy(owner)
            );
            Resource memory stamp = getResource(stampResources[0]);
            return stamp.metadataURI;
        } else {
            return "User does not have stamp";
        }
    }

    function letterboxMetadataURI(uint256 letterboxTokenId)
        public
        view
        returns (string memory)
    {
        //ATTENTION add try catch

        uint64[] memory letterboxResources = getActiveResources(
            letterboxTokenId
        );
        Resource memory letterbox = getResource(letterboxResources[0]);
        (string memory metadata, uint64 id) = (
            letterbox.metadataURI,
            letterbox.id
        );
        //used to return duple of metadata + resouce id.. removed resource id from return due to changes 10/23
        return metadata;
    }

    function resourceCount(uint256 tokenId_) public view returns (uint256) {
        //RMRKMultiResource _multiResource;
        return getActiveResources(tokenId_).length;
    }

    // --- Public ---
    // -- Contract Admin Stuff --

    function withdraw() public payable onlyAdmin isNotPaused {
        payable(msg.sender).transfer(address(this).balance);
    }

    function nextResourceId() public view returns (uint64) {
        uint64 nextResource = uintFixerFun(_resourceIdAuto.current());
        return nextResource;
    }

    function feeSetter(uint256 newMintFee_) public onlyAdmin {
        _mintFee = newMintFee_;
    }

    function feeGetter() public view returns (uint256) {
        return _mintFee;
    }

    function pauseContract(bool state) public onlyAdmin {
        paused = state;
        emit ContractPaused(paused);
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    //
    //   Internal Functions -----
    //
    function createAndAddResource(
        uint256 tokenId_,
        string memory resourceMetadata,
        bool isAccepted
    ) internal {
        uint64 resourceId = nextResourceId();
        addResourceEntry(resourceMetadata);
        _addResourceToToken(tokenId_, resourceId, 0); // i believe if overwrite is 0 it will prevent from overwriting a token.

        if (isAccepted == true) {
            uint64[] memory pendingResources = getPendingResources(tokenId_);
            if (pendingResources.length >= 1) {
                uint256 tokenToApprove = pendingResources.length - 1;
                _acceptResource(tokenId_, tokenToApprove);
            } else {
                //error
            }
        }
    }

    function addResourceEntry(string memory metadataURI) internal isNotPaused {
        //this is to set the variable as a uint64  - could be an issue if overflow?
        uint64 currentResource = nextResourceId();
        _addResourceEntry(currentResource, metadataURI);
        _resourceIdAuto.increment();
    }

    //
    //   Private Functions ---
    //
    function mapLetterboxAddr(address to_, uint256 tokenId_) private {
        letterboxesToAddresses[to_].letterboxIds.push(tokenId_);
    }

    function mapStampAddr(address to_, uint tokenId_) private {
        //ATTENTION - review and remove commented section here
        //modifier on caller function should be isStampEligible
        // require(
        //     stampsToAddresses[to_] == 0,
        //     "address already has stamp, do not mint"
        // );

        stampsToAddresses[to_] = tokenId_;
    }

    //hack to solve a problem, probably not a great way to handle this
    function uintFixerFun(uint256 resourceId_) private pure returns (uint64) {
        return uint64(resourceId_);
    }

    //creates a stamp with the URI passed for first (therefore primary) resource
    //automatically adds and approves the initial upload as a resource.

    function mintInitial(address to_, string memory resourceURI_)
        private
        returns (uint256)
    {
        //mint a token to accept the resource.
        uint256 tokenIdNow = _tokenIdAuto.current();
        _safeMint(to_, tokenIdNow);

        //this is an argument we need to pass with the add resource function but currently have not used

        createAndAddResource(tokenIdNow, resourceURI_, true);

        _tokenIdAuto.increment();
        //returns the tokenid used for making this token to be added to a mapping
        return tokenIdNow;
    }
}
