import geojson, heapq, os
import pandas as pd
from collections import defaultdict
from math import radians, sin, cos, asin, sqrt

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GEOJSON_PATH = os.path.join(BASE_DIR, "../data/Jaringan_jalanan_indonesia.geojson")
BIDAN_CSV_PATH = os.path.join(BASE_DIR, "../data/bidan_points.csv")

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    dlat, dlon = radians(lat2-lat1), radians(lon2-lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)**2
    return 2*R*asin(sqrt(a))

def load_graph_from_geojson(path):
    with open(path, "r", encoding="utf-8") as f:
        gj = geojson.load(f)
    features = gj["features"]
    min_lon, max_lon, min_lat, max_lat = 106.6, 107.0, -6.4, -6.05
    nodes, rev_nodes, adj = {}, {}, defaultdict(list)

    def inside_jakarta(lon, lat):
        return (min_lon <= lon <= max_lon) and (min_lat <= lat <= max_lat)

    def get_id(lat, lon):
        key = (round(lat,6), round(lon,6))
        if key not in nodes:
            idx = len(nodes)
            nodes[key], rev_nodes[idx] = idx, key
        return nodes[key]

    for feat in features:
        coords, gtype = feat["geometry"]["coordinates"], feat["geometry"]["type"]
        lines = [coords] if gtype=="LineString" else coords
        for line in lines:
            for i in range(len(line)-1):
                lon1, lat1, lon2, lat2 = line[i][0], line[i][1], line[i+1][0], line[i+1][1]
                if not (inside_jakarta(lon1,lat1) and inside_jakarta(lon2,lat2)):
                    continue
                u,v = get_id(lat1,lon1), get_id(lat2,lon2)
                w = haversine_km(lat1,lon1,lat2,lon2)
                adj[u].append((v,w)); adj[v].append((u,w))
    return nodes, rev_nodes, adj

def nearest_node(lat, lon, rev_nodes):
    best, best_d = None, float("inf")
    for idx,(nlat,nlon) in rev_nodes.items():
        d = haversine_km(lat, lon, nlat, nlon)
        if d<best_d:
            best, best_d = idx,d
    return best

def dijkstra(adj, source, target):
    pq, dist, prev, visited = [(0.0, source)], {source:0.0}, {}, set()
    while pq:
        d,u = heapq.heappop(pq)
        if u in visited: continue
        visited.add(u)
        if u==target: break
        for v,w in adj.get(u,[]):
            nd = d+w
            if v not in dist or nd<dist[v]:
                dist[v], prev[v] = nd, u
                heapq.heappush(pq,(nd,v))
    if target not in dist: return float("inf"), []
    path=[target]
    while path[-1]!=source:
        path.append(prev[path[-1]])
    return dist[target], list(reversed(path))

# load data
if not os.path.exists(BIDAN_CSV_PATH):
    pd.DataFrame([
        [1,"Bidan Sari",-6.2005,106.8233,4.8,"Jl. Melati 1","0812-1111-1111"],
        [2,"Bidan Dewi",-6.2091,106.8292,4.7,"Jl. Kenanga 2","0812-2222-2222"],
        [3,"Bidan Ayu",-6.2173,106.8325,4.9,"Jl. Mawar 3","0812-3333-3333"]
    ], columns=["id","name","lat","lon","rating","address","phone"]).to_csv(BIDAN_CSV_PATH,index=False)

nodes, rev_nodes, adj = load_graph_from_geojson(GEOJSON_PATH)
bidan_df = pd.read_csv(BIDAN_CSV_PATH)
