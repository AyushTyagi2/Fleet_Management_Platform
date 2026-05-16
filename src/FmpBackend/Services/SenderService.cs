using System;
using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class SenderService
{
    private readonly OrganizationRepository _orgs;
    private readonly UserRepository _users;
    private readonly AddressRepository _addresses;

    public SenderService(
        OrganizationRepository orgs,
        UserRepository users,
        AddressRepository addresses)
    {
        _orgs = orgs;
        _users = users;
        _addresses = addresses;
    }

    public void OnboardSender(SenderOnboardingDto dto)
    {
        var existing = _orgs.GetByPhone(dto.Phone);
        if (existing != null)
            throw new Exception("Organization already exists");

        var org = new Organization
        {
            Id = Guid.NewGuid(),
            Name = dto.OrgName,
            OrganizationType = dto.OrgType,
            PrimaryContactName = dto.ContactName,
            PrimaryContactPhone = dto.Phone,
            PrimaryContactEmail = dto.Email,
            Industry = dto.Industry,
            Description = dto.Description,
            AddressLine1 = dto.AddressLine,
            City = dto.City,
            State = dto.State,
            PostalCode = dto.PostalCode,
            Status = "active",
            CreatedAt = DateTime.UtcNow
        };
        _orgs.Create(org);

        // 1. Create the User record so shipment creation can find it
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = dto.Email,
            Phone = dto.Phone,
            FullName = dto.ContactName,
            Status = "active",
            KycStatus = "verified",
            CreatedAt = DateTime.UtcNow
        };
        _users.Create(user);

        // 2. Create the Address record so pickup address lookup works
        var address = new Address
        {
            Id = Guid.NewGuid(),
            OwnerId = org.Id,
            OwnerType = "organization",
            AddressLine1 = dto.AddressLine,
            City = dto.City,
            State = dto.State,
            PostalCode = dto.PostalCode,
            IsDefault = true,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _addresses.Create(address);
    }
}

