// Example Slang shader
import Graphics;

interface IComparable
{
    int compareTo(This other);
}

struct Vertex : IComparable
{
    float3 position : SV_Position;
    float3 normal : NORMAL;
    
    __init(float3 pos, float3 norm)
    {
        position = pos;
        normal = norm;
    }
    
    int compareTo(This other)
    {
        return position.z < other.position.z ? -1 : 1;
    }
}

[numthreads(8, 8, 1)]
void computeMain(uint3 id : SV_DispatchThreadID)
{
    float4 color = saturate(sin(id.x) * cos(id.y));
    RWTexture2D[id.xy] = color;
} 