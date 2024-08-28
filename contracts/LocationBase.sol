// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;
import "./interfaces/ILocation.sol";
import "./interfaces/ILocationController.sol";
import "./interfaces/IEntity.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract LocationBase is ILocation, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    ILocationController immutable locationController;
    bytes32 public constant VALID_ROUTE_SETTER =
        keccak256("VALID_ROUTE_SETTER");

    bytes32 public constant VALID_ENTITY_SETTER =
        keccak256("VALID_ENTITY_SETTER");

    EnumerableSet.AddressSet validSources;
    EnumerableSet.AddressSet validDestinations;

    EnumerableSet.AddressSet validEntities;
    event OnDeparture(IEntity entity, uint256 entityID, ILocation to);
    event OnArrival(IEntity entity, uint256 entityID, ILocation from);

    constructor(ILocationController _locationController) {
        locationController = _locationController;
        _grantRole(VALID_ROUTE_SETTER, msg.sender);
        _grantRole(VALID_ENTITY_SETTER, msg.sender);
    }

    modifier onlyEntityOwner(IEntity entity, uint256 entityId) {
        require(msg.sender == entity.ownerOf(entityId), "Only entity owner");
        _;
    }

    modifier onlyLocalEntity(IEntity _entity, uint256 _entityId) {
        require(
            address(this) ==
                address(
                    locationController.getEntityLocation(_entity, _entityId)
                ),
            "Only local entity"
        );
        _;
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityID,
        ILocation _from
    ) public virtual {
        require(msg.sender == address(locationController), "Sender must be LC");
        require(validSources.contains(address(_from)), "Invalid source");
        require(validEntities.contains(address(_entity)), "Invalid entity");
        emit OnArrival(_entity, _entityID, _from);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual {
        require(msg.sender == address(locationController), "Sender must be LC");
        require(
            validDestinations.contains(address(_to)),
            "Invalid destination"
        );
        require(validEntities.contains(address(_entity)), "Invalid entity");
        emit OnDeparture(_entity, _entityID, _to);
    }

    function setValidDestionation(
        ILocation[] calldata _destinations,
        bool isValid
    ) public onlyRole(VALID_ROUTE_SETTER) {
        if (isValid) {
            for (uint i; i < _destinations.length; i++) {
                validDestinations.add(address(_destinations[i]));
            }
        } else {
            for (uint i; i < _destinations.length; i++) {
                validDestinations.remove(address(_destinations[i]));
            }
        }
    }

    function setValidRoute(
        ILocation[] calldata _locations,
        bool isValid
    ) public onlyRole(VALID_ROUTE_SETTER) {
        if (isValid) {
            for (uint i; i < _locations.length; i++) {
                validSources.add(address(_locations[i]));
                validDestinations.add(address(_locations[i]));
            }
        } else {
            for (uint i; i < _locations.length; i++) {
                validSources.remove(address(_locations[i]));
                validDestinations.remove(address(_locations[i]));
            }
        }
    }

    function setValidEntities(
        IEntity[] calldata _entities,
        bool isValid
    ) public onlyRole(VALID_ENTITY_SETTER) {
        if (isValid) {
            for (uint i; i < _entities.length; i++) {
                validEntities.add(address(_entities[i]));
            }
        } else {
            for (uint i; i < _entities.length; i++) {
                validEntities.remove(address(_entities[i]));
            }
        }
    }

    //High gas usage, view only
    function viewOnly_getAllValidSources()
        external
        view
        override
        returns (address[] memory locations_)
    {
        locations_ = validSources.values();
    }

    function getValidSourceCount() public view override returns (uint256) {
        return validSources.length();
    }

    function getValidSourceAt(
        uint256 _i
    ) public view override returns (ILocation) {
        return ILocation(validSources.at(_i));
    }

    //High gas usage, view only
    function viewOnly_getAllValidDestinations()
        external
        view
        override
        returns (address[] memory locations_)
    {
        locations_ = validDestinations.values();
    }

    function getValidDestinationCount() public view override returns (uint256) {
        return validDestinations.length();
    }

    function getValidDestinationAt(
        uint256 _i
    ) public view override returns (ILocation) {
        return ILocation(validDestinations.at(_i));
    }

    //High gas usage, view only
    function viewOnly_getAllValidEntities()
        external
        view
        override
        returns (address[] memory entities_)
    {
        entities_ = validEntities.values();
    }

    function getValidEntitiesCount() public view override returns (uint256) {
        return validEntities.length();
    }

    function getValidEntitiesAt(
        uint256 _i
    ) public view override returns (IEntity) {
        return IEntity(validEntities.at(_i));
    }
}
