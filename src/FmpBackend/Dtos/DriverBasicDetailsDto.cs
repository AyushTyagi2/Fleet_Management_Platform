namespace FmpBackend.Dtos;

public class DriverBasicDetailsDto
{
    public string Phone { get; set; } = null!;
    public string VehicleNumber { get; set; } = null!;
    public string vehicleType { get; set; } = null!;
    public string licenseNumber { get; set; } = null!;
    public string? FleetCode { get; set; }  // ← add this
}