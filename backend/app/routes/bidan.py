from fastapi import APIRouter, HTTPException
from app.map_utils import bidan_df, rev_nodes, adj, nearest_node, dijkstra, haversine_km

router = APIRouter()

# Endpoint daftar bidan (Flutter expect /bidan_list)
@router.get("/bidan_list")
def get_bidan_all():
    return bidan_df.to_dict(orient="records")

# Endpoint route (Flutter expect /route)
@router.get("/route")
def get_route(user_lat: float, user_lon: float, bidan_id: int):
    match = bidan_df[bidan_df["id"] == bidan_id]
    if match.empty:
        raise HTTPException(status_code=404, detail="Bidan tidak ditemukan")
    dest = match.iloc[0]

    s_id = nearest_node(user_lat, user_lon, rev_nodes)
    t_id = nearest_node(dest["lat"], dest["lon"], rev_nodes)

    if s_id is None or t_id is None:
        raise HTTPException(status_code=500, detail="Tidak dapat menemukan node")

    dist_km, path_ids = dijkstra(adj, s_id, t_id)

    # Jika gagal cari jalur → fallback ke straight line (garis lurus)
    if not path_ids:
        straight = haversine_km(user_lat, user_lon, dest["lat"], dest["lon"])
        return {
            "dist_km": straight,
            "path": [
                {"lat": user_lat, "lon": user_lon},
                {"lat": dest["lat"], "lon": dest["lon"]}
            ],
            "dest": {"lat": dest["lat"], "lon": dest["lon"]}
        }

    path = [{"lat": rev_nodes[n][0], "lon": rev_nodes[n][1]} for n in path_ids]
    return {
        "dist_km": dist_km,
        "path": path,
        "dest": {"lat": dest["lat"], "lon": dest["lon"]}
    }
