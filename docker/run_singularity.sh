#!/bin/bash

create_mount ()
{
  mount_name=$1
  path=`greadlink -f $2`
  source_path=`dirname $path`
  target_path=$ROOT_MOUNT_DIRECTORY/$mount_name
  echo "Mounting $source_path -> $target_path" 1>&2
  if [ -z "$SINGULARITY_BIND" ]
  then
    export SINGULARITY_BIND="$source_path:$target_path"
  else
    export SINGULARITY_BIND="${SINGULARITY_BIND},$source_path:$target_path"
  fi
  echo $target_path
}

DOWNLOAD_DIR='SET ME'
output_dir='/tmp/alphafold'

model_names=( \
  'model_1' \
  'model_2' \
  'model_3' \
  'model_4' \
  'model_5' \
)

data_dir=$DOWNLOAD_DIR
myargs=""

uniref90_database_path="$DOWNLOAD_DIR/uniref90/uniref90.fasta"
myargs="$myargs --uniref90_database_path=`create_mount uniref90_database_path $uniref90_database_path`"

# Path to the MGnify database for use by JackHMMER.
mgnify_database_path="$DOWNLOAD_DIR/mgnify/mgy_clusters_2018_12.fa"
myargs="$myargs --mgnify_database_path=`create_mount mgnify_database_path $mgnify_database_path`"

# Path to the BFD database for use by HHblits.
bfd_database_path="$DOWNLOAD_DIR/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
myargs="$myargs --bfd_database_path=`create_mount bfd_database_path $bfd_database_path`"

# Path to the Small BFD database for use by JackHMMER.
#small_bfd_database_path="$DOWNLOAD_DIR/small_bfd/bfd-first_non_consensus_sequences.fasta"
#myargs="$myargs --bfd_database_path=`create_mount bfd_database_path $bfd_database_path`"

# Path to the Uniclust30 database for use by HHblits.
uniclust30_database_path="$DOWNLOAD_DIR/uniclust30/uniclust30_2018_08/uniclust30_2018_08"
myargs="$myargs --uniclust30_database_path=`create_mount uniclust30_database_path $uniclust30_database_path`"

# Path to the PDB70 database for use by HHsearch.
pdb70_database_path="$DOWNLOAD_DIR/pdb70/pdb70"
myargs="$myargs --pdb70_database_path=`create_mount pdb70_database_path $pdb70_database_path`"

# Path to a directory with template mmCIF structures, each named <pdb_id>.cif')
template_mmcif_dir="$DOWNLOAD_DIR/pdb_mmcif/mmcif_files"
myargs="$myargs --template_mmcif_dir=`create_mount template_mmcif_dir $template_mmcif_dir`"

# Path to a file mapping obsolete PDB IDs to their replacements.
obsolete_pdbs_path="$DOWNLOAD_DIR/pdb_mmcif/obsolete.dat"
myargs="$myargs --obsolete_pdbs_path=`create_mount obsolete_pdbs_path $obsolete_pdbs_path`"

ROOT_MOUNT_DIRECTORY='/mnt'

while :; do
  case $1 in
    --fasta_paths)       # Takes an option argument; ensure it has been specified.
      i=0
      fasta=""
      for FASTA_PATH in ${2//,/ }
      do
        echo $FASTA_PATH
        target_fasta_path=$(create_mount "fasta_path_${i}" "$FASTA_PATH")
        if [ -z "$fasta" ]
        then
          fasta="$target_fasta_path"
        else
          fasta="$fasta,$target_fasta_path"
        fi
        let i=i+1
      done
      myargs="$myargs --fasta_paths=$fasta"
    
      shift
      ;;
    --max_template_date)       # Takes an option argument; ensure it has been specified.
      max_template_date=$2
      shift
      ;;
    --)              # End of all options.
      shift
      break
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *)               # Default case: No more options, so break out of the loop.
      break
  esac
 
  shift
done


# Create output
export SINGULARITY_BIND=$SINGULARITY_BIND,${output_dir}:${ROOT_MOUNT_DIRECTORY}/output

command_args="$myargs --output_dir=${ROOT_MOUNT_DIRECTORY}/output --model_name=${model_names// /,} --max_template_date=${max_template_date} --preset=full_dbs --benchmark=0 --logtostderr"

echo $command_args
echo $SINGULARITY_BIND
echo singularity run --nv $ALPHAFOLD_IMAGE $command_args



