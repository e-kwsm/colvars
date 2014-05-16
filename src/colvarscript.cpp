#include "colvarscript.h"

colvarscript::colvarscript (colvarproxy *p)
 : proxy (p)
{
  colvars = proxy->colvars;
}

/// Run method based on given arguments
int colvarscript::run (int argc, char *argv[]) {

  result = "";

  if (cvm::debug()) {
    cvm::log ("Called script run with " + cvm::to_str(argc) + " args");
    for (int i = 0; i < argc; i++) { cvm::log (argv[i]); }
  }

  if (argc < 2) {
    result = "Missing arguments";
    return COLVARSCRIPT_ERROR;
  }

  std::string cmd = argv[1];
  
  if (cmd == "colvar") {
    return proc_colvar (argc-1, &(argv[1])); 
  }

  if (cmd == "bias") {
    return proc_bias (argc-1, &(argv[1])); 
  }

  if (cmd == "reset") {
    /// Delete every child object
    // Implementation postponed until delayed initialization is in place
    // colvars = proxy->reset_cvm ();
    return COLVARSCRIPT_OK;
  }
  
  if (cmd == "update") { 
    colvars->calc();
    return COLVARSCRIPT_OK;
  }


  /// Parse config from file
  //int colvarscript::configfile (std::string const &filename) {
    // Implementation postponed until delayed initialization is in place

  /// Parse config from string
  if (cmd == "config") {
    std::string conf = argv[2];
    // Partial implementation: we are not reading global options
    colvars->init_colvars (conf);
    colvars->init_biases (conf);
    return COLVARSCRIPT_OK;
  }

  result = "Syntax error";
  return COLVARSCRIPT_ERROR;
}


int colvarscript::proc_colvar (int argc, char *argv[]) {
  std::string name = argv[1];
  colvar *cv = cvm::colvar_by_name (name);
  if (cv == NULL) {
    result = "Colvar not found: " + name;
    return COLVARSCRIPT_ERROR;
  }
  if (argc < 3) {
    result = "Missing parameters";
    return COLVARSCRIPT_ERROR;
  }
  std::string subcmd = argv[2];

  if (subcmd == "value") {
    result = cvm::to_str(cv->value(), 0, 14);
    return COLVARSCRIPT_OK;
  }

  if (subcmd == "update") {
    // note: this is not sufficient for a newly created colvar
    // as atom coordinates may not be properly loaded
    // a full CVM update is required
    // or otherwise updating atom positions
    cv->update();
    result = cvm::to_str(cv->value(), 0, 14);
    return COLVARSCRIPT_OK;
  }

  if (subcmd == "delete") {
    if (cv->biases.size() > 0) {
      result = "Cannot delete a colvar currently used by biases, delete those biases first";
      return COLVARSCRIPT_ERROR;
    }
    // colvar destructor is tasked with the cleanup
    delete cv;
    return COLVARSCRIPT_OK;
  }

  result = "Syntax error";
  return COLVARSCRIPT_ERROR;
}


int colvarscript::proc_bias (int argc, char *argv[]) {
  std::string name = argv[1];
  colvarbias *b = cvm::bias_by_name (name);
  if (b == NULL) {
    result = "Bias not found: " + name;
    return COLVARSCRIPT_ERROR;
  }

  if (argc < 3) {
    result = "Missing parameters";
    return COLVARSCRIPT_ERROR;
  }
  std::string subcmd = argv[2];

  if (subcmd == "energy") {
    result = cvm::to_str(b->get_energy());
    return COLVARSCRIPT_OK;
  }

  if (subcmd == "update") {
    b->update();
    result = cvm::to_str(b->get_energy());
    return COLVARSCRIPT_OK;
  }

  if (subcmd == "delete") {
    // the bias destructor takes care of the cleanup at cvm level
    delete b;
    return COLVARSCRIPT_OK;
  }

  if (argc >= 4) {
    std::string param = argv[3];

    result = "Syntax error";
    return COLVARSCRIPT_ERROR;
  }
  result = "Syntax error";
  return COLVARSCRIPT_ERROR;
}
