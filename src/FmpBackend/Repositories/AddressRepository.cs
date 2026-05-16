using System;
using FmpBackend.Models;
using FmpBackend.Data;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Repositories;

public class AddressRepository
{
    private readonly AppDbContext _context;

    public AddressRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Address?> GetDefaultByOwnerAsync(Guid ownerId, string ownerType)
    {
        return await _context.Addresses
            .Where(a =>
                a.OwnerId == ownerId &&
                a.OwnerType == ownerType &&
                a.IsDefault &&
                a.IsActive)
            .FirstOrDefaultAsync();
    }
      public async Task<Address?> GetAnyActiveByOwnerAsync(Guid ownerId, string ownerType)
{
    return await _context.Addresses
        .Where(a => a.OwnerId == ownerId && a.OwnerType == ownerType && a.IsActive)
        .FirstOrDefaultAsync();
}
public async Task<Address?> GetByIdAsync(Guid id)
{
    return await _context.Addresses
        .FirstOrDefaultAsync(a => a.Id == id);
}

public async Task<Address> CreateAsync(Address address)
{
    if (address.Id == Guid.Empty)
    {
        address.Id = Guid.NewGuid();
    }

    if (address.CreatedAt == default)
    {
        address.CreatedAt = DateTime.UtcNow;
    }

    address.UpdatedAt = DateTime.UtcNow;
    _context.Addresses.Add(address);
    await _context.SaveChangesAsync();
    return address;
}

public void Create(Address address)
{
    if (address.Id == Guid.Empty)
    {
        address.Id = Guid.NewGuid();
    }

    if (address.CreatedAt == default)
    {
        address.CreatedAt = DateTime.UtcNow;
    }

    address.UpdatedAt = DateTime.UtcNow;
    _context.Addresses.Add(address);
    _context.SaveChanges();
}
}