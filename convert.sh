#!/bin/bash

# 1次+2次メッシュ番号のリスト
MESH_LIST=(
  533900
  533901
  533902
  533903
  533904
  533905
  533906
  533907
  533910
  533911
  533912
  533913
  533914
  533915
  533916
  533917
  533920
  533921
  533922
  533923
  533924
  533925
  533926
  533927
  533930
  533931
  533932
  533933
  533934
  533935
  533936
  533937
  533940
  533941
  533942
  533943
  533944
  533945
  533946
  533947
  533950
  533951
  533952
  533953
  533954
  533955
  533956
  533957
  533960
  533961
  533962
  533963
  533964
  533965
  533966
  533967
  533970
  533971
  533972
  533973
  533974
  533975
  533976
  533977
)

# 出力先ディレクトリ
OUTPUT_DIR=./output_tiles
mkdir -p "$OUTPUT_DIR"

# 各メッシュ番号ループ
for MESH in "${MESH_LIST[@]}"; do

    MESH1_CODE="${MESH:0:4}"   # 5339
    MESH2="${MESH:4:2}"        # 11
    Y="${MESH2:0:1}"
    X="${MESH2:1:1}"

    # 上2桁・下2桁
    MESH1_NLAT=$(( MESH1_CODE / 100 ))   # N1 = 53
    MESH1_NLON=$(( MESH1_CODE % 100 ))   # N2 = 39

    # 正しい緯度・経度の起点
    ORIGIN_LON=$(python3 -c "print(100 + $MESH1_NLON)")        # 東経
    ORIGIN_LAT=$(python3 -c "print($MESH1_NLAT / 1.5)")        # 北緯

    # 2次メッシュのサイズ
    DX=1/8
    DY=1/12

    # bbox 計算
    read MIN_LON <<< $(python3 -c "print($ORIGIN_LON + ($X - 1) * $DX)")
    read MIN_LAT <<< $(python3 -c "print($ORIGIN_LAT + ($Y - 1) * $DY)")
    read MAX_LON <<< $(python3 -c "print($MIN_LON + $DX)")
    read MAX_LAT <<< $(python3 -c "print($MIN_LAT + $DY)")

    BBOX="$MIN_LON,$MIN_LAT,$MAX_LON,$MAX_LAT"

    echo "=== Processing メッシュ ${MESH} ($BBOX) ==="

    # 1. basemap 切り出し
    rm -f $OUTPUT_DIR/mapbox_road_${MESH}.mbtiles
    tilelive-copy \
        --bbox="$BBOX" \
        ~/data/mbtiles/mapbox/streets-japan-v8/mapbox_road.mbtiles \
        $OUTPUT_DIR/mapbox_road_${MESH}.mbtiles

    # 2. water 切り出し
    rm -f $OUTPUT_DIR/mapbox_water_${MESH}.mbtiles
    tilelive-copy \
        --bbox="$BBOX" \
        ~/data/mbtiles/mapbox/streets-japan-v8/mapbox_water.mbtiles \
        $OUTPUT_DIR/mapbox_water_${MESH}.mbtiles

    # 3. マージ
    rm -f "$OUTPUT_DIR/merge_${MESH}.mbtiles"
    tile-join \
        -f \
        -o "$OUTPUT_DIR/merge_${MESH}.mbtiles" \
        "$OUTPUT_DIR/mapbox_road_${MESH}.mbtiles" \
        "$OUTPUT_DIR/mapbox_water_${MESH}.mbtiles"

    # 4. 展開
    rm -rf "$OUTPUT_DIR/merge_${MESH}_dir"
    mb-util --image_format=pbf \
        "$OUTPUT_DIR/merge_${MESH}.mbtiles" \
        "$OUTPUT_DIR/merge_${MESH}_dir"

    # 5. zip
    rm -f "$OUTPUT_DIR/merge_${MESH}.zip"
    zip -r "$OUTPUT_DIR/merge_${MESH}.zip" "$OUTPUT_DIR/merge_${MESH}_dir"

    echo "=== Done メッシュ ${MESH} ==="
done

echo "All done."
